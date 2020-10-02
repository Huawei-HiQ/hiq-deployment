cmake_minimum_required(VERSION 2.8.12)
project(pybind11-example)

find_package(pybind11 REQUIRED)
pybind11_add_module(example example.cpp)
