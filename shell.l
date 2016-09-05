
/*
 *
 * CS-252 Spring 2015
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <string.h>
#include <unistd.h>
#include "y.tab.h"
#include "tty.h"
#include <sys/wait.h>

char *fizDefinitions[100];
int numDefs = 0;

static  void yyunput (int c,char *buf_ptr  );

int ttygetc(FILE *f)
{
    static char *s = NULL;
    static char *lineBuf;

    char c;
    if (!isatty(0))
        return getc(f); // No need to use the line editor

    // If s is null, we need input. Grab it from the line editor.
    if (s == NULL)
    {
        lineBuf = ttygetline(TTY_MAX_LINEBUFFER);
        s = lineBuf;
    }

    c = *s++; // Read one character from our buffer
    if (!*s) // Check if we are at the end of the current line buffer
    {
        free(lineBuf);
        s = NULL;
    }

    // Return a char like getc would
    return c;
}

int addDefinition(char *def) {
	
	fizDefinitions[numDefs++] = strdup(def);	

	return 0;
}

int redefineDefinition(char *def) {

	int newSize = strlen(def) - 2;
	char *newDef = (char *)malloc(newSize*sizeof(char));
	newDef[0] = '(';
	for (int i = 1; i < newSize; i++) {
		newDef[i] = def[i+2];
	}

	int checkSize = 8;
	while (newDef[checkSize] != ' ') {
		checkSize++;
	}

	int found = 0;
	for (int i = 0; i < numDefs; i++) {
		if (strncmp(newDef, fizDefinitions[i], checkSize) == 0) {
			free(fizDefinitions[i]);
			fizDefinitions[i] = newDef;
			found = 1;
			return 0;
		}
	}
	
	addDefinition(newDef);
	return 0;
}

void removeLast() {
	if (numDefs != 0) {
		numDefs--;
		free(fizDefinitions[numDefs]);
		printf("Removed!\n");
	} else {
		printf("No definitions stored.\n");
	}
}

int removeFiz(char *str) {
	//printf("String : %s\n", str);
	int removed = 0;
	for (int i = 0; i < numDefs - 1; i++) {
		if (strncmp(str, fizDefinitions[i], strlen(str)) == 0) {
			removed = 1;
		}
		if (removed == 1) {
			free(fizDefinitions[i]);
			fizDefinitions[i] = strdup(fizDefinitions[i+1]);
		}
	}

	if(removed == 0) {
		printf("Definition not found.\n");
		return -1;
	} else {
		free(fizDefinitions[numDefs--]);
	}

	return 0;
}

void runSubshell(char *str) {

	//create pipe
	int fdpipe[2];
	pipe(fdpipe);

	int tmpIn = dup(0);
	int tmpOut = dup(1);

	int newOut = fdpipe[1];
	int newIn = fdpipe[0];

	//create second pipe
	int fdpipe2[2];
	pipe(fdpipe2);
	int newOut2 = fdpipe2[1];
	int newIn2 = fdpipe2[0];

	char *newStr = (char*)malloc(2048);
	newStr[0] = '\0';

	char* args[2];
	args[1] = NULL;
	args[0] = "shell";

	dup2(newIn, 0);
	close(newIn);

	dup2(newOut2, 1);
	close(newOut2);

	int pid = fork();
	if ( pid < 0 ) {
		exit( 2 );
	} else if (pid == 0) {
		close(newOut);
		close(newIn);

		close(newOut2);
		close(newIn2);

		execvp("/proc/self/exe", args);

		_exit(0);
	}
	
	dup2(tmpIn, 0);
	dup2(tmpOut, 1);

	write(newOut, str, strlen(str));
	write(newOut, "\n", 1);
	close(newOut);

	waitpid(pid, NULL, 0);

	//readcharacters
	char ch;
	int bytes;
	while ((bytes = read(newIn2, &ch, 1)) > 0) {
			char c[2];
			c[0] = ch;
			c[1] = '\0';
			strcat(newStr, c);
	}

	for (int i = strlen(newStr) - 1; i >= 0; i--) {
		if (newStr[i] == '\n') {
			unput(' ');
		} else {
			unput(newStr[i]);
		}
	}

	free(newStr);
}

void runFiz(char *str) {

	int isDefine = 0;

	if (strncmp(str, "(define ", 8) == 0) {
		if ((addDefinition(str)) == -1) {
			unput(' ');
			return;
		}
		isDefine = 1;
	} else if (strncmp(str, "(redefine ", 10) == 0) {
		if ((redefineDefinition(str)) == -1) {
			unput(' ');
			return;
		}
		isDefine = 1;
	}

	//create pipe
	int fdpipe[2];
	pipe(fdpipe);

	int tmpIn = dup(0);
	int tmpOut = dup(1);

	int newOut = fdpipe[1];
	int newIn = fdpipe[0];

	//create second pipe
	int fdpipe2[2];
	pipe(fdpipe2);
	int newOut2 = fdpipe2[1];
	int newIn2 = fdpipe2[0];

	char *newStr = (char*)malloc(2048*sizeof(char));
	newStr[0] = '\0';

	char* args[2];
	args[1] = NULL;
	args[0] = "fiz";

	dup2(newIn, 0);
	close(newIn);

	dup2(newOut2, 1);
	close(newOut2);

	int pid = fork();
	if ( pid < 0 ) {
		exit( 2 );
	} else if (pid == 0) {
		close(newOut);
		close(newIn);

		close(newOut2);
		close(newIn2);

		char *execPath = (char *)malloc(1024*sizeof(char));
		readlink("/proc/self/exe", execPath, 1024);
		
		char fizPath[1024];
		fizPath[0] = '\0';

		int len = 0;
		while (execPath[strlen(execPath) - len] != '/') {
			len++;
		}
		strncat(fizPath, execPath, strlen(execPath) - len);
		strcat(fizPath, "/lab2-src/fiz");

		execvp(fizPath, args);

		_exit(0);
	}
	
	dup2(tmpIn, 0);
	dup2(tmpOut, 1);

	for (int i = 0; i < numDefs; i++) {
		//printf("Definition to fiz: %s\n", fizDefinitions[i]);
		write(newOut, fizDefinitions[i], strlen(fizDefinitions[i]));
		write(newOut, "\n", 1);
		//printf("Inputed!\n");
	}

	if (isDefine == 0) {
		write(newOut, str, strlen(str));
		write(newOut, "\n", 1);
	}
	close(newOut);

	waitpid(pid, NULL, 0);

	//readcharacters
	char ch;
	int bytes;
	while ((bytes = read(newIn2, &ch, 1)) > 0) {
			//printf("Char: %c\n", ch);
			char c[2];
			c[0] = ch;
			c[1] = '\0';
			strcat(newStr, c);
	}

	for (int i = strlen(newStr) - 0; i >= 5; i--) {
		if ((newStr[i] == '>') && (newStr[i-1] == 'z') && (newStr[i-2] == 'i') && (newStr[i-3] == 'f')) {
			i = i - 3;
		} else {
			if ((newStr[i] == '!') || (newStr[i] == '\n')) {
				unput(' ');
			} else {
				unput(newStr[i]);
			}
		}
	}

	free(newStr);
}

#undef getc
#define getc(f) ttygetc(f)

void myunputc(int c) {
    unput(c);
}

%}

%%

\n 	{
		return NEWLINE;
	}

[ \t] 	{
		/* Discard spaces and tabs */
     	}	

"exit"	{
		return EXIT;
}

"setenv" {
		return SETENV;
}

"unsetenv" {
		return UNSETENV;
}

"fiz remove last definition" {
		removeLast();
		return FIZ;
}

"fiz remove "[^\t\n]+ {
		char* arg = strdup(yytext);
		int size = strlen(arg);
		int newsize = size - 1;
		char* newArg = (char *)malloc(newsize*sizeof(char));
		*(newArg) = '\0';
		strcat(newArg, "(define (");

		for (int i = 9; i < newsize; i++) {
			*(newArg + i) = *(arg + i + 2);
		}
		*(newArg + newsize) = '\0';
		free(arg);	
		
		//yylval.string_val = newArg;
		removeFiz(newArg);
		return FIZ;
}

">" 	{
		return GREAT;
	}

">>"	{
		return GREATGREAT;
	}

"<" 	{
		return LESS;
	}

"|"	{
		return PIPE;
	}

"&"	{
		return AMPERSAND;
	}

">&"	{
		return GREATAMPERSAND;
	}

">>&"	{
		return GREATGREATAMPERSAND;
	}

"^.*${[^}]+}.*$" {
		return WORD;
	}

`[^\n`]+`  {
		char* arg = strdup(yytext);
		int size = strlen(arg);
		int newsize = size - 2;
		char* newArg = (char *)malloc(newsize*sizeof(char));

		for (int i = 0; i < newsize; i++) {
			*(newArg + i) = *(arg + i + 1);
		}
		*(newArg + newsize) = '\0';
		free(arg);	
		
		//yylval.string_val = newArg;
		runSubshell(newArg);
	}

\[\[[^\n`]+\]\]  {
		char* arg = strdup(yytext);
		int size = strlen(arg);
		int newsize = size - 4;
		char* newArg = (char *)malloc(newsize*sizeof(char));

		for (int i = 0; i < newsize; i++) {
			*(newArg + i) = *(arg + i + 2);
		}
		*(newArg + newsize) = '\0';
		free(arg);	
		
		//yylval.string_val = newArg;
		runFiz(newArg);
	}

\"[^\n\"][^\n\"]*\"  {
		char* arg = strdup(yytext);
		int size = strlen(arg);
		int newsize = size - 2;
		char* newArg = (char *)malloc((newsize+1)*sizeof(char));

		for (int i = 0; i < newsize; i++) {
			*(newArg + i) = *(arg + i + 1);
		}
		free(arg);
		*(newArg + newsize) = '\0';
		
		yylval.string_val = newArg;
		return WORD;
	}

((\\[\&\\\{\}\"(\>)(\<)])*([^| \t\n><&])*)+  {
		/* Assume that file names have only alpha chars */
		yylval.string_val = strdup(yytext);
		return WORD;
	}

