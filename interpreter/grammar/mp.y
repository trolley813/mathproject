%{
#include <iostream>
#include "../../kernel/AST.h"
#include "../../kernel/UserFunction.h"
#include "../../kernel/Type.h"
#include "../../kernel/Error.h"
#include "../../kernel/Matrix.h"
#include <string>
#include <vector>
#include <map>
#include <set>

using namespace std;
using namespace Kernel;

extern int yylex();
extern int yylineno;
void yyerror(Kernel::AST* a, char* msg) {
    Error::error(ET_SYNTAX, { msg });
}

extern FILE* yyin;

static std::string opMarker = "$operator";

extern volatile int inside;

inline bool isInteractive() {
    return yyin == stdin and !inside;
}

map<string, double> prec = {
    {opMarker + "^",  9},
    {opMarker + "*",  8},
    {opMarker + "/",  8},
    {opMarker + "%",  8},
    {opMarker + "!",  8},
    {opMarker + "+",  7},
    {opMarker + "-",  7},
    {opMarker + "<",  6},
    {opMarker + "<=", 6},
    {opMarker + ">",  6},
    {opMarker + ">=", 6},
    {opMarker + "==", 5},
    {opMarker + "!=", 5},
    {opMarker + "&",  4},
    {opMarker + "@",  3},
    {opMarker + "|",  2},
    {opMarker + "=",  1}
};

set<string> right_assoc = {opMarker + "^", opMarker + "="};

static bool last_term = 0;

%}
%error-verbose
%token <type> FLOAT
%token <str> ID
%token <str> OPERATOR
%token SEMICOLON COMMA 
%token LEFTPAR RIGHTPAR LEFTBRACE RIGHTBRACE LEFTBRK RIGHTBRK
%token IF WHILE ELSE FUNCTION RETURN
%type <ast> program block bracedblock instruction expression term
%type <arglist> arglist
%type <exprlist> exprlist
%type <row> row
%type <rowlist> rowlist
%type <type> matrix
%right OPERATOR
%right IFX ELSE
%union
{
    Type *type;
    Kernel::AST *ast;
    char* str;
    std::vector<std::string> *arglist;
    std::vector<Kernel::AST*> *exprlist;
    std::vector<double> *row;
    std::vector<std::vector<double>> *rowlist;
}
%start program
%parse-param {Kernel::AST *&result}
%%
program: block {
           $$ = result = $1;
           cout << typeid(*result).name() << endl;
       }
block: block instruction {
            ((BlockAST*)$1)->children.push_back($2);
            $$ = $1;
       }
       | instruction {
            $$ = new BlockAST();
            ((BlockAST*)$$)->children.push_back($1);
       }
bracedblock : LEFTBRACE block RIGHTBRACE {
                /*inside = 1;*/
                $$ = $2;
                /*inside = 0;*/
}
instruction: IF expression instruction %prec IFX {
                $$ = new ConditionalAST($2, $3, 0);
                if(isInteractive()) {
                    result = $$;
                    return 0;
                }
           }
           | IF expression instruction ELSE instruction {
                $$ = new ConditionalAST($2, $3, $5);
                if(isInteractive()) {
                    result = $$;
                    return 0;
                }
           }
           | WHILE expression instruction {
                $$ = new WhileLoopAST($2, $3);
                if(isInteractive()) {
                    result = $$;
                    return 0;
                }
           }
           | FUNCTION ID LEFTPAR arglist RIGHTPAR instruction {
                UserFunction* f = new UserFunction($6, *$4);
                //cout << "Function BODY: " << $2 << endl;
                AST::functions[$2] = f;
                $$ = new FunctionBodyAST(f);
                if(isInteractive()) {
                    result = $$;
                    return 0;
                }
           }
           | RETURN expression SEMICOLON {
                $$ = new ReturnAST($2);
                if(isInteractive()) {
                    result = $$;
                    return 0;
                }
           }
           | expression SEMICOLON {
                $$ = $1;
                if(isInteractive()) {
                    result = $$;
                    return 0;
                }
           }
           | bracedblock {
                $$ = $1;
                if(isInteractive()) {
                    result = $$;
                    return 0;
                }
           }
arglist: arglist COMMA ID {
           $1->push_back($3);
           $$ = $1;
       }
       | ID {
           $$ = new std::vector<std::string>;
           $$->push_back($1);
       }
exprlist: exprlist COMMA expression {
            $1->push_back($3);
            $$ = $1;
        }
        | expression {
            $$ = new std::vector<Kernel::AST*>;
            $$->push_back($1);
        }
expression: expression OPERATOR expression {
              double last = INT_MAX;
              if(dynamic_cast<FunctionAST*>($3) and !last_term)
                  last = prec.find(((FunctionAST*)($3))->function) == prec.end() ?
                         INT_MAX : prec[((FunctionAST*)($3))->function];
              double added = prec.find(opMarker + $2) == prec.end() ? INT_MIN : prec[opMarker + $2];
              cout << "Added: " << added << " Last: " << last << endl;
              if(right_assoc.count(opMarker + $2) ? added <= last : added < last) {
                  std::vector<AST*> v = { $1, $3 };
                  $$ = new FunctionAST(opMarker + $2, v);
              }
              else {
                  AST* tmp = ((FunctionAST*)($3))->arguments[0];
                  ((FunctionAST*)($3))->arguments[0] = new FunctionAST(opMarker + $2, {$1, tmp});
                  $$ = $3;
              }
              last_term = 0;
          }
          | OPERATOR expression {
              std::vector<AST*> v = { $2 };
              $$ = new FunctionAST(opMarker + $1, v);
          }
          | term {
              $$ = $1;
              last_term = 1;
          }
term: FLOAT {
        $$ = new TypeAST($1);
    }
    | ID {
        $$ = new VarAST($1);
    }
    | matrix {
        $$ = new TypeAST($1);
    }
    | LEFTPAR expression RIGHTPAR {
        $$ = $2;
    }
    | ID LEFTPAR exprlist RIGHTPAR {
        $$ = new FunctionAST($1, *$3);
    }
    | ID LEFTBRK exprlist RIGHTBRK {
        $3->insert($3->begin(), new VarAST($1));
        $$ = new FunctionAST("$index", *$3);
    }
matrix: LEFTBRACE rowlist RIGHTBRACE {
          $$ = new Matrix(*$2);
      }
rowlist: rowlist SEMICOLON row {
           $1->push_back(*$3);
           $$ = $1;
       }
       | row {
           $$ = new std::vector<std::vector<double>>;
           $$->push_back(*$1);
       }
row: row COMMA FLOAT {
         $1->push_back(((Matrix*)$3)->element(1, 1));
         $$ = $1;
   }
   | FLOAT {
         $$ = new std::vector<double>;
         $$->push_back(((Matrix*)$1)->element(1, 1));
   }
%%