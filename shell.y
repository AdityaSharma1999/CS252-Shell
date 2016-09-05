
/*
 * CS-252 Spring 2015
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * You must extend it to understand the complete shell grammar.
 *
 */

%token	<string_val> WORD
%token	<string_val> SUBSHELL
%token	<string_val> FIZ

%token 	NOTOKEN GREAT LESS NEWLINE GREATGREAT PIPE AMPERSAND GREATAMPERSAND GREATGREATAMPERSAND
%token  EXIT PRINTENV SETENV UNSETENV

%union	{
		char   *string_val;
	}

%{
//#define yylex yylex
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/types.h>
#include "command.h"
#include "tty.h"

void yyerror(const char * s);
int yylex();

extern char ** environ;
%}

%%

goal:	
	commands
	;

commands: 
	command
	| commands command 
	;

command:	
	pipe_list io_list background_optional NEWLINE {
		//printf("   Yacc: Execute command\n");
		if (Command::_currentCommand._outChange > 1) {
			printf("Ambiguous output redirect.");
		} else if (Command::_currentCommand._inChange > 1) {
			printf("Ambiguous input redirect.");
		} else if (Command::_currentCommand._errChange > 1) {
			printf("Ambiguous error redirect.");
		} else {
			Command::_currentCommand.execute();
		}
	}
	| NEWLINE 
	| error NEWLINE { yyerrok; }
	| EXIT NEWLINE {
		printf("Good bye!!\n");
		ttyteardown();
		exit(0);
	}
	| PRINTENV NEWLINE {
		int i = 0;
		while (*(environ + i) != NULL) {
			printf("%s\n", *(environ + i));
			i++;
		}
		exit(0);
	}
	| SETENV WORD WORD NEWLINE {
		setenv( $2, $3, 1);
	}
	| UNSETENV WORD NEWLINE {
		unsetenv( $2 );
	}
	| FIZ NEWLINE {
		Command::_currentCommand.prompt();
	}
	;

command_and_args:
	command_word arg_list {
		Command::_currentCommand.insertSimpleCommand( Command::_currentSimpleCommand );
	}
	;

arg_list:
	arg_list argument
	| /* can be empty */
	;

argument:
	WORD {
              Command::_currentCommand.wildArg( $1 );
	}
	;

command_word:
	WORD {
              //printf("   Yacc: insert command \"%s\"\n", $1);
	       
	       Command::_currentSimpleCommand = new SimpleCommand();
	       Command::_currentSimpleCommand->insertArgument( $1 );
	}
	;

pipe_list:
	pipe_list PIPE command_and_args
	| command_and_args
	;

io_list:
	io_list iomodifier_opt
	| /* can be empty */
	;

iomodifier_opt:
	GREAT WORD {
		//printf("   Yacc: insert output \"%s\"\n", $2);
		Command::_currentCommand._outFile = $2;
		Command::_currentCommand._outChange++;
	}
	| LESS WORD {
		//printf("   Yacc: insert output \"%s\"\n", $2);
		Command::_currentCommand._inputFile = $2;
		Command::_currentCommand._inChange++;
	}
	| GREATAMPERSAND WORD {
		//printf("   Yacc: insert output \"%s\"\n", $2);
		Command::_currentCommand._outFile = $2;
		Command::_currentCommand._outChange++;
		Command::_currentCommand._errFile = $2;
		Command::_currentCommand._errChange++;
	}
	| GREATGREAT WORD {
		//printf("   Yacc: insert output \"%s\"\n", $2);
		Command::_currentCommand._append = 1;
		Command::_currentCommand._outFile = $2;
		Command::_currentCommand._outChange++;
	}
	| GREATGREATAMPERSAND WORD {
		//printf("   Yacc: insert output \"%s\"\n", $2);
		Command::_currentCommand._append = 1;
		Command::_currentCommand._outFile = $2;
		Command::_currentCommand._outChange++;
		Command::_currentCommand._errFile = $2;
		Command::_currentCommand._errChange++;
	}
	;

background_optional:
	AMPERSAND {
		Command::_currentCommand._background = 1;
	}
	| /* can be empty */
	;

%%

void
yyerror(const char * s)
{
	fprintf(stderr,"%s", s);
}

#if 0
main()
{
	yyparse();
}
#endif
