%{
#include <iostream>
#include <vector>
#include <string>
#include <stdlib.h>
#include <stdio.h>
#include "s_table.h"
// #define YACC_PRINT
#define USEPRINT
#ifdef USEPRINT
#define Trace(t)		printf(t)
#else
#define Trace(t)
#endif
extern "C" {
	int yyerror(const char *s);
	extern int yylex();
	extern int yylineno;
        extern FILE* yyin;
}

symbolTables symTabs = symbolTables();

%}

/* tokens */
%union{
	struct{
		int tokenType; // 0:int 1:float 2:bool 3:string
		bool notInit;
		union{
			int intVal;
			float floatVal;
			bool boolVal;
			char* stringVal;
		};
	} Token;
}

%token OPEARATOR_LESS_EQUAL
%token OPEARATOR_MORE_EQUAL
%token OPEARATOR_NOT_EQUAL
%token OPEARATOR_AND
%token OPEARATOR_OR
%token OPEARATOR_ASSIGIN

%token KEYWORD_ARRAY
%token KEYWORD_BOOLEAN
%token KEYWORD_BEGIN
%token KEYWORD_BREAK
%token KEYWORD_CHAR
%token KEYWORD_CASE
%token KEYWORD_CONST
%token KEYWORD_CONTINUE
%token KEYWORD_DO
%token KEYWORD_ELSE
%token KEYWORD_END
%token KEYWORD_EXIT
%token KEYWORD_FALSE
%token KEYWORD_FOR
%token KEYWORD_FN
%token KEYWORD_IF
%token KEYWORD_IN
%token KEYWORD_INTEGER
%token KEYWORD_LOOP
%token KEYWORD_MODULE
%token KEYWORD_PRINT
%token KEYWORD_PRINTLN
%token KEYWORD_PROCEDURE
%token KEYWORD_REPEAT
%token KEYWORD_RETURN
%token KEYWORD_REAL
%token KEYWORD_STRING
%token KEYWORD_RECORD
%token KEYWORD_THEN
%token KEYWORD_TURE
%token KEYWORD_TYPE
%token KEYWORD_USE
%token KEYWORD_UTIL
%token KEYWORD_VAR
%token KEYWORD_WHILE
%token KEYWORD_OF
%token KEYWORD_READ

%token <Token> INTEGER
%token <Token> STRING
%token <Token> REAL
%token <Token> BOOLEAN
%token <Token> ID
%type <Token> expression type integerExpr realExpr boolExpr stringExpr funcInvoc

%start program
%left OPEARATOR_OR
%left OPEARATOR_AND
%left '~'
%left '>' '<' '=' OPEARATOR_MORE_EQUAL OPEARATOR_LESS_EQUAL OPEARATOR_NOT_EQUAL
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%%
program:        KEYWORD_MODULE ID declarations mainfunc	{ 
                        Trace("Reducing to start\n"); 
                        symTabs.pop_table();
                }
	        |	KEYWORD_MODULE ID mainfunc    { 
                                Trace("Reducing to start\n"); 
                                symTabs.pop_table();
                }
		;
declarations:   declaration {
                    Trace("Reducing to declarations\n");
                }
                |       declaration declarations    {
                        Trace("Reducing to declarations\n");
                }
                ;
declaration:    const   {
                    Trace("Reducing to declaration\n");
                }
                |       var     {
                                Trace("Reducing to declaration\n");
                }
                |       array   {
                                Trace("Reducing to declaration\n");
                }
                |       procedure       {
                                Trace("Reducing to declaration\n");
                }
                ;
const:      KEYWORD_CONST consts    {
                Trace("Reducing to type Form const\n");
            }
            ;
consts:     ID '=' expression ';'   {
                Trace("Reducing to type Form consts\n");
            }
            |   ID '=' expression ';' consts  {
                    Trace("Reducing to type Form consts\n");
            }
            ;
ids:    ID  {
                Trace("Reducing to type Form id\n");
        }
        |       ID ',' ids   {
                        Trace("Reducing to type Form id\n");
        }
        ;
var:        KEYWORD_VAR vars    {
                Trace("Reducing to type Form var\n");
            }
            ;
vars:       ids ':' type ';'   {
                Trace("Reducing to type Form vars\n");
            }
            |   ids '=' type ';' vars  {
                    Trace("Reducing to type Form vars\n");
            }
            ;
array:      ids ':' KEYWORD_ARRAY '[' expression ',' expression ']' KEYWORD_OF type ';' {
                Trace("Reducing to type Form array\n");
            }
type:   KEYWORD_INTEGER  {
	        Trace("Reducing to type Form KEYWORD_INTEGER\n");
                $$.tokenType = T_INT;
	}
	|	KEYWORD_REAL    {
	                Trace("Reducing to type Form KEYWORD_REAL\n");
                        $$.tokenType = T_REAL;
		}
	|	KEYWORD_BOOLEAN {
	                Trace("Reducing to type Form KEYWORD_BOOLEAN\n");
                        $$.tokenType = T_BOOL;
		}
	|	KEYWORD_STRING  {
		        Trace("Reducing to type Form KEYWORD_STRING\n");
                        $$.tokenType = T_STRING;
		}
        ;
procedure:  KEYWORD_PROCEDURE ID subfunc   {
                Trace("Reducing to procedure\n");
            }
            |   KEYWORD_PROCEDURE ID declarations subfunc   {
                    Trace("Reducing to procedure\n");
            }
            |   KEYWORD_PROCEDURE ID '(' arguments ')' subfunc  {
                    Trace("Reducing to procedure\n");
            }
            |   KEYWORD_PROCEDURE ID '(' arguments ')' declarations subfunc {
                    Trace("Reducing to procedure\n");
            }
            |   KEYWORD_PROCEDURE ID ':' type subfunc   {
                    Trace("Reducing to procedure\n");
            }
            |   KEYWORD_PROCEDURE ID ':' type declarations subfunc  {
                    Trace("Reducing to procedure\n");
            }
            |   KEYWORD_PROCEDURE ID '(' arguments ')' ':' type subfunc    {
                    Trace("Reducing to procedure\n");
            }
            |   KEYWORD_PROCEDURE ID '(' arguments ')' ':' type declarations subfunc    {
                    Trace("Reducing to procedure\n");
            }
            ;
arguments:  argument    {
                Trace("Reducing to arguments\n");
            }
            |   argument ',' arguments  {
                Trace("Reducing to arguments\n");
            }
            ;
argument:   ID ':' type  {
                Trace("Reducing to argument\n");
            }
            ;
mainfunc:   KEYWORD_BEGIN statements KEYWORD_END ID '.' {
                Trace("Reducing to mainfunc\n");
            }
            |   KEYWORD_BEGIN KEYWORD_END ID '.' {
                    Trace("Reducing to mainfunc\n");
            }   
            ;
subfunc:    KEYWORD_BEGIN statements KEYWORD_END ID ';' {
                Trace("Reducing to subfunc\n");
            }      
            ;
statements:     statement   {
                        Trace("Reducing to statements\n");
                }
                |       statement statements    {
                                Trace("Reducing to statement statements\n");
                }
                ;



statement:  ID OPEARATOR_ASSIGIN expression ';' {
                Trace("Reducing to statement");
            }
            |   ID '[' expression ']' OPEARATOR_ASSIGIN expression ';' {
                    Trace("Reducing to statement\n");
            }
            |   KEYWORD_PRINT expression ';'    {
                    Trace("Reducing to statement\n");
            }
            |   KEYWORD_PRINTLN expression ';'  {
                    Trace("Reducing to statement\n");
            }
            |   KEYWORD_READ expression ';' {
                    Trace("Reducing to statement\n");
            }   
            |   KEYWORD_RETURN ';'      {
                    Trace("Reducing to statement\n");
            }
            |   KEYWORD_RETURN expression ';'   {
                    Trace("Reducing to statement\n");
            }
            |   ifCon   {
                    Trace("Reducing to statement\n");
            }
            |   loopCon   {
                    Trace("Reducing to statement\n");
            }
            ;
expression:     expression '+' expression   {
                        Trace("Reducing to expression\n");
                }
                |       expression '-' expression   {
                                Trace("Reducing to expression\n");
                }
                |       expression '*' expression   {
                                Trace("Reducing to expression\n");
                }
                |       expression '/' expression   {
                                Trace("Reducing to expression\n");
                }
                |       '-' expression %prec UMINUS {
                                Trace("Reducing to expression\n");
                }            
                |       '(' expression ')'  {
                                Trace("Reducing to expression\n"); 
                }
	        |	integerExpr { 
                                Trace("Reducing to expression\n");
                }
	        |	realExpr    { 
                                Trace("Reducing to expression\n");
                }
	        |	boolExpr	{ 
                                Trace("Reducing to expression\n");
                }
	        |	stringExpr  { 
                                Trace("Reducing to expression\n");
                }
	        |	funcInvoc   { 
                                Trace("Reducing to expression\n");
                }
	        |	ID  { 
                                Trace("ID Reducing to expression\n");
                }
	        |	ID '[' integerExpr ']'  { 
                                Trace("Reducing to expression\n");
                }
	        ;
integerExpr:    INTEGER { 
                        Trace("Reducing to integerExpr Form INTEGER\n");
                }
		;
realExpr:       REAL    { 
                        Trace("Reducing to realExpr Form REAL\n");
                }
	        ;
boolExpr:       KEYWORD_TURE    {
                        Trace("Reducing to boolExpr\n");
                }
                |       KEYWORD_FALSE   {
                                Trace("Reducing to boolExpr\n");
                }
                |       expression '>' expression   {
                                Trace("Reducing to boolExpr\n");
                }
                |       expression '<' expression   {
                                Trace("Reducing to boolExpr\n");
                }            
                |       expression '=' expression   {
                                Trace("Reducing to boolExpr\n");
                }
                |       expression OPEARATOR_LESS_EQUAL expression  {
                                Trace("Reducing to boolExpr\n");
                }
                |       expression OPEARATOR_MORE_EQUAL expression  {
                                Trace("Reducing to boolExpr\n");
                }
                |       expression OPEARATOR_NOT_EQUAL expression   {
                                Trace("Reducing to boolExpr\n");
                }
                |       expression '~' expression   {
                                Trace("Reducing to boolExpr\n");
                }
                |       expression OPEARATOR_AND expression {
                                Trace("Reducing to boolExpr\n");
                }
                |       expression OPEARATOR_OR expression  {
                                Trace("Reducing to boolExpr\n");
                }
                ;
stringExpr:     STRING  { 
                        Trace("Reducing to stringExpr Form STRING\n");
                }
        	;
funcInvoc:	ID '(' ')'      { 
		        Trace("Reducing to functionInvoc\n");
		}
                |       ID '(' parameters ')'   { 
		                Trace("Reducing to functionInvoc\n");
		}
                ;
parameters:     expression      {
                        Trace("Reducing to parameters\n");
                }
                |       expression ',' parameters       {
                                Trace("Reducing to parameters\n");
                }
                ;
ifCon:  KEYWORD_IF '(' boolExpr ')' KEYWORD_THEN KEYWORD_END ';'     {
                Trace("Reducing to stringExpr Form ifCon\n");
        }
        |       KEYWORD_IF '(' boolExpr ')' KEYWORD_THEN statements KEYWORD_END ';'     {
                        Trace("Reducing to stringExpr Form ifCon\n");
        }
        |       KEYWORD_IF '(' boolExpr ')' KEYWORD_THEN elseCon KEYWORD_END ';'     {
                        Trace("Reducing to stringExpr Form ifCon\n");
        }
        |       KEYWORD_IF '(' boolExpr ')' KEYWORD_THEN statements  elseCon KEYWORD_END ';'     {
                        Trace("Reducing to stringExpr Form ifCon\n");
        }
        ;
elseCon:        KEYWORD_ELSE statements {
                        Trace("Reducing to stringExpr Form elseCon\n");
                }
                |       KEYWORD_ELSE    {
                                Trace("Reducing to stringExpr Form elseCon\n");
                }
                ;
loopCon:        KEYWORD_WHILE '(' boolExpr ')' KEYWORD_DO statements KEYWORD_END ';'    {
                        Trace("Reducing to stringExpr Form loopCon\n");
                }
                |       KEYWORD_WHILE '(' boolExpr ')' KEYWORD_DO KEYWORD_END ';'    {
                                Trace("Reducing to stringExpr Form loopCon\n");
                } 
                ;    
%%

int yyerror(const char *msg)
{
        fprintf(stderr, "%s\n", msg);
        exit(0);
        return 0;
}

int main(int argc, char *argv[])
{
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */

    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */
}