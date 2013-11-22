/*
 ============================================================================
 Name        : append_gp_header.c
 Author      : Jan Johansson
 Version     : 1.0
 Copyright   :
 Description : Append a (gp) header to a binary created for a beagle bone
               black. The result is a mlo file to be stored in a non-XIP.
               Reference: AM335x ARM® Cortex™-A8 Microprocessors (MPUs),
               Technical Reference Manual

               append_gp_header <in file> <start addr> <static part of header>
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>

#define MLO_START_ADDR 0x402f0400
#define MLO_STATIC_HEAD	512


int main(int argc, char *argv[]) {
	uint32_t	i;
	char		inFileName[FILENAME_MAX];
	char		outFileName[FILENAME_MAX] = "MLO";
	char		headerFileName[FILENAME_MAX];
	char		ch;
	FILE		*inFile = NULL, *outFile = NULL, *headerFile = NULL;
	uint32_t	startAddr = MLO_START_ADDR, size = 0;
	struct stat	sinfo;

	// Create a binary to use for the creation of the static part of the header
	// Temp - Copy the static part of the header to the file below
/*
	strcpy(inFileName, "MLO_1");
	strcpy(outFileName, "static_gp_header.bin");

	inFile = fopen(inFileName, "rb");
	outFile = fopen(outFileName, "wb");

	for (i=0; i < 512; i++) {
		fread(&ch, 1, 1, inFile);
		fwrite(&ch, 1, 1, outFile);
	}

	fclose(inFile);
	fclose(outFile);
	return EXIT_SUCCESS;
*/
	// Temp - end

	if (4 == argc) {
		strcpy(inFileName, argv[1]);
		startAddr = strtol(argv[2], NULL, 16);
		strcpy(headerFileName, argv[3]);
	}
	else {
		printf("invalid number of arguments\n");
		return EXIT_SUCCESS;
	}

	inFile = fopen(inFileName, "rb");
	if (inFile == NULL) {
		printf("cannot open %s\n", inFileName);
		return EXIT_SUCCESS;
	}

	stat(inFileName, &sinfo);
	size = sinfo.st_size;

	outFile = fopen(outFileName, "wb");
	if (outFile == NULL) {
		printf("cannot open %s\n", outFileName);
		fclose(inFile);
		return EXIT_SUCCESS;
	}

	headerFile = fopen(headerFileName, "rb");
	if (headerFile == NULL) {
		printf("cannot open %s\n", headerFileName);
		return EXIT_SUCCESS;
	}

	// write the static part of the header
	for (i=0; i < MLO_STATIC_HEAD; i++) {
		fread(&ch, 1, 1, headerFile);
		fwrite(&ch, 1, 1, outFile);
	}

	// write the address and size part of the header
	fwrite(&size, 1, 4, outFile);
	fwrite(&startAddr, 1, 4, outFile);

	// write the content of the MLO
	for (i=0; i < size; i++) {
		fread(&ch, 1, 1, inFile);
		fwrite(&ch, 1, 1, outFile);
	}

	fclose(inFile);
	fclose(outFile);
	fclose(headerFile);

	return EXIT_SUCCESS;
}
