// genRam.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include "pch.h"
#include <iostream>

int main(int argc, char **argv)
{
    std::cout << "Starting!\n"; 

    int addr = 0;
    FILE *fp_in = fopen("F:\\FpgaProjects\\genRam\\Debug\\turnmon.bin.mem", "rb");
    FILE *fp_out = fopen("F:\\FpgaProjects\\genRam\\Debug\\turnmon.out.txt", "w");
    while (!feof(fp_in))
    {
      int h=0;
      //h = fgetc(fp_in);
      fscanf(fp_in, "%02x", &h);
      fprintf(fp_out, "ram[%d] = 8'h%02x; ", addr, h);
      ++addr;
      if (addr % 4 == 0)
      {
        fprintf(fp_out, " \n ");
      }

    }
    fclose(fp_in);
    fclose(fp_out);
}

// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file
