//
// Created by R2 on 06.07.2015.
//

#include "Matrix.h"
#include "Error.h"

Matrix::Matrix(int rows, int columns) : sizeColumn(columns), sizeRow(rows) {
    array = new double *[rows];
    for (int i = 0; i < rows; i++) array[i] = new double[columns];
}

Matrix::Matrix(double number) : Matrix(1, 1) {
    **array = number;
}

Matrix::~Matrix() {
    for (int i = 0; i < sizeRow; i++) delete[] array[i];
    delete[] array;
}

std::string Matrix::getType() {
    return "Matrix";
}

bool Matrix::equals(Type &type) {
    return false;
}

double &Matrix::element(int i, int j) {
    return array[i - 1][j - 1];
}

bool Matrix::isNonzero() {
    for (int i = 0; i < sizeRow; i++)
        for (int j = 0; j < sizeColumn; j++)
            if (array[i][j]) return true;
    return false;
}

Matrix::Matrix(vector<vector<double>> &v) {
    sizeRow = v.size();
    sizeColumn = 0;
    for (int i = 0; i < sizeRow; i++) {
        if (v[i].size() > sizeColumn) sizeColumn = v[i].size();
    }
    array = new double *[sizeRow];
    for (int i = 0; i < sizeRow; i++) array[i] = new double[sizeColumn];
    for (int i = 0; i < sizeRow; i++) {
        for (int j = 0; j < sizeColumn; j++) {
            array[i][j] = v[i].size() > j ? v[i][j] : 0;
        }
    }
}

Matrix Matrix::operator+(Matrix &other) {
    if (other.sizeRow != sizeRow or other.sizeColumn != sizeColumn) Error::error(ET_DIMENSIONS_MISMATCH);
    Matrix res = Matrix(sizeRow, sizeColumn);
    for (int i = 0; i < sizeRow; i++)
        for (int j = 0; j < sizeColumn; j++)
            res.array[i][j] = array[i][j] + other.array[i][j];
    return res;
}

Matrix Matrix::operator-(Matrix &other) {
    if (other.sizeRow != sizeRow or other.sizeColumn != sizeColumn) Error::error(ET_DIMENSIONS_MISMATCH);
    Matrix res = Matrix(sizeRow, sizeColumn);
    for (int i = 0; i < sizeRow; i++)
        for (int j = 0; j < sizeColumn; j++)
            res.array[i][j] = array[i][j] - other.array[i][j];
    return res;
}

Matrix Matrix::operator*(Matrix &other) {
    if (sizeColumn == 1 and sizeRow == 1) {
        Matrix res = Matrix(other.sizeRow, other.sizeColumn);
        for (int i = 0; i < other.sizeRow; i++)
            for (int j = 0; j < other.sizeColumn; j++)
                res.array[i][j] = other.array[i][j] * array[0][0];
        return res;
    }
    if (other.sizeColumn == 1 and other.sizeRow == 1) {
        Matrix res = Matrix(sizeRow, sizeColumn);
        for (int i = 0; i < sizeRow; i++)
            for (int j = 0; j < sizeColumn; j++)
                res.array[i][j] = array[i][j] * other.array[i][j];
        return res;
    }
    if (sizeColumn != other.sizeRow) Error::error(ET_DIMENSIONS_MISMATCH);
    Matrix res = Matrix(sizeRow, other.sizeColumn);
    for (int i = 0; i < sizeRow; i++)
        for (int j = 0; j < other.sizeColumn; j++) {
            for (int k = 0; k < sizeColumn; j++)
                res.array[i][j] += array[i][k] * other.array[k][j];

        }
    return res;
}
