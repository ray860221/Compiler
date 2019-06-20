%{
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <stdlib.h>
#include <stdio.h>
#include "s_table.h"

#define YACC_PRINT

#ifdef YACC_PRINT
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

using namespace std;

string outputfileName = "proj3";
fstream fp;
int nowTabs = 0;
void printTabs();

symbolTables symTabs = symbolTables();
vector<string> id_arr;

bool hasReturned = false;		// if no input return, fp << "return"; 
bool nowIsConstant = false;		// if constant use symtabs.
int nowStackIndex = 0;
int nowLabelIndex = 0;

vector<int> topElseLabel;

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
%union{
	struct{
		int beginLabel;
		int exitLabel;
	} whileKeep;
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
%token KEYWORD_TRUE
%token KEYWORD_TYPE
%token KEYWORD_USE
%token KEYWORD_UTIL
%token KEYWORD_VAR
// %token KEYWORD_WHILE
%token KEYWORD_OF
%token KEYWORD_READ

%token <whileKeep> KEYWORD_WHILE

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
program:        KEYWORD_MODULE ID declarations funcs     { 
                        Trace("Reducing to start\n"); 
                        // symTabs.pop_table();
                        
                }
		;
declarations:   declaration {
                    Trace("Reducing to declarations\n");
                }
                |       declarations declaration    {
                        Trace("Reducing to declarations\n");
                }

                ;
declaration:    const   {
                    Trace("Reducing to declaration\n");
                }
                |       var     {
                                Trace("Reducing to declaration\n");
                }
                |       %empty  { Trace("Reducing to declaration Form empty\n"); }
                // |       array   {
                //                 Trace("Reducing to declaration\n");
                // }
                ;
funcs:   func    {
                Trace("Reducing to func\n");
        }
        |       funcs func    {
                Trace("Reducing to func\n");
                }
        ;
const:  KEYWORD_CONST consts    {
                Trace("Reducing to const\n");
        }
        ;
consts: ID '='  {
                nowIsConstant = true;
        }
        expression ';'   {
                Trace("Reducing to constDec Form ID '=' expression ';'\n");

		variableEntry ve = ve_basic($1.stringVal, $4.tokenType, true);
		if ($4.tokenType == T_INT)
			ve.data.intVal = $4.intVal;
		else if ($4.tokenType == T_REAL)
			ve.data.floatVal = $4.floatVal;
		else if ($4.tokenType == T_BOOL)
			ve.data.boolVal = $4.boolVal;
		else if ($4.tokenType == T_STRING)
			ve.data.stringVal = $4.stringVal;
		if (!symTabs.addVariable(ve))
			yyerror("Re declaration.");
		nowIsConstant = false;
        }
        |       consts  ID '='  {
                        nowIsConstant = true;
                }
                expression ';'  {
                        Trace("Reducing to constDec Form ID '=' expression ';'\n");

                        variableEntry ve = ve_basic($2.stringVal, $5.tokenType, true);
                        if ($5.tokenType == T_INT)
                                ve.data.intVal = $5.intVal;
                        else if ($5.tokenType == T_REAL)
                                ve.data.floatVal = $5.floatVal;
                        else if ($5.tokenType == T_BOOL)
                                ve.data.boolVal = $5.boolVal;
                        else if ($5.tokenType == T_STRING)
                                ve.data.stringVal = $5.stringVal;
                        if (!symTabs.addVariable(ve))
                                yyerror("Re declaration.");
                        nowIsConstant = false;
                }
        ;
ids:    ID  {
                Trace("Reducing to type Form id\n");
                id_arr.push_back($1.stringVal);
        }
        |       ID ',' ids   {
                        Trace("Reducing to type Form id\n");
                        id_arr.push_back($1.stringVal);
        }
        ;
var:        KEYWORD_VAR vars    {
                Trace("Reducing to type Form var\n");
            }
            ;
vars:   ids ':' type ';'   {
                Trace("Reducing to varDec Form ids ':' type ';'\n");
                for(int i = 0; i < id_arr.size(); i++){
                        variableEntry ve = ve_basic_notInit(id_arr[i], $3.tokenType, false);
                        if (symTabs.isNowGlobal())
                        {
                                ve.isGlobal = true;
                                printTabs();
                                if (ve.type== T_INT)
                                        fp << "field static int " << ve.name << endl;
                                else if (ve.type == T_BOOL)
                                        fp << "field static int " << ve.name << endl;
				else if (ve.type == T_REAL)
                                        fp << "field static float " << ve.name << endl;
				else if (ve.type == T_STRING)
                                        fp << "field static java.lang.String " << ve.name << endl;
                        }
                        else
                        {
                                ve.isGlobal = false;
                                ve.stackIndex = nowStackIndex;
                                nowStackIndex++;
                        }
                        if (!symTabs.addVariable(ve))
                                yyerror("Re declaration.");
                }
                id_arr.clear();        
        }
        |       vars ids ':' type ';'   {
                        Trace("Reducing to varDec Form ids ':' type ';'\n");
                        for(int i = 0; i < id_arr.size(); i++){
                                variableEntry ve = ve_basic_notInit(id_arr[i], $4.tokenType, false);
                                if (symTabs.isNowGlobal())
                                {
                                        ve.isGlobal = true;
                                        printTabs();
                                        if (ve.type== T_INT)
                                                fp << "field static int " << ve.name << endl;
                                        else if (ve.type == T_BOOL)
                                                fp << "field static int " << ve.name << endl;
					else if (ve.type == T_STRING)
                                        	fp << "field static string " << ve.name << endl;
                                }
                                else
                                {
                                        ve.isGlobal = false;
                                        ve.stackIndex = nowStackIndex;
                                        nowStackIndex++;
                                }
                                if (!symTabs.addVariable(ve))
                                        yyerror("Re declaration.");
                        } 
                        id_arr.clear();         
                }
        ;
// array:      ids ':' KEYWORD_ARRAY '[' expression ',' expression ']' KEYWORD_OF type ';' {
//                 Trace("Reducing to type Form array\n");
//             }
//         ;
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
func:           KEYWORD_PROCEDURE ID '('        {
                        variableEntry ve = ve_fn($2.stringVal, T_NONE);
			if (!symTabs.addVariable(ve))
				yyerror("Re declaration.");
			symTabs.push_table($2.stringVal);
			nowStackIndex = 0;
			hasReturned = false;
			printTabs();
			fp << "method public static ";
                } 
                arguments ')' funcType  {
                        variableEntry ve = symTabs.nowFuncVE();
                        if (ve.type == T_INT)
				fp << "int ";
			else if (ve.type == T_BOOL)
				fp << "bool ";
			else
				fp << "void ";
			fp << ve.name;
			fp << "(";
			for (int i = 0; i < ve.argSize; i++)
			{
				if (ve.argType[i] == T_INT)
					fp << "int";
				else if (ve.argType[i] == T_BOOL)
					fp << "bool";
				if (i != ve.argSize - 1)
					fp << ", ";
			}
			fp << ")" << endl;
			printTabs();
			fp << "max_stack 15" << endl;
			printTabs();
			fp << "max_locals 15" << endl;
			printTabs();
			fp << "{" << endl;
			nowTabs++;
                } 
                declarations subfunc    {
                        Trace("Reducing to functionDec KEYWORD_PROCEDURE ID '(' arguments ')' funcType subfunc\n");
		        if (!hasReturned) 
		        {
		        	printTabs();
		        	fp << "return" << endl;
		        }
		        nowTabs--;
		        printTabs();
		        fp << "}" << endl;
                        symTabs.pop_table();
                }
                |       KEYWORD_BEGIN   {
                                symTabs.push_table("this");
                                printTabs();
                                fp << "method public static void main(java.lang.String[])" << endl;
                                printTabs();
                                fp << "max_stack 15" << endl;
                                printTabs();
                                fp << "max_locals 15" << endl;
                                printTabs();
                                fp << "{" << endl;
                                nowTabs++;
                        } 
                        statements KEYWORD_END ID '.' {
                                Trace("Reducing to mainfunc from statements KEYWORD_END ID '.'\n");
                                symTabs.pop_table();
                                printTabs();
                                fp << "return" << endl;
                                nowTabs--;
                                printTabs();
                                fp << "}" << endl;
                                symTabs.pop_table();
                        }
                // |       KEYWORD_BEGIN   {
                //                 symTabs.push_table("this");
                //                 printTabs();
                //                 fp << "method public static void main(java.lang.String[])" << endl;
                //                 printTabs();
                //                 fp << "max_stack 15" << endl;
                //                 printTabs();
                //                 fp << "max_locals 15" << endl;
                //                 printTabs();
                //                 fp << "{" << endl;
                //                 nowTabs++;
                //         } 
                //         KEYWORD_END ID '.' {
                //                 Trace("Reducing to mainfunc from KEYWORD_END ID '.'\n");
                //                 symTabs.pop_table();
                //                 printTabs();
                //                 fp << "return" << endl;
                //                 nowTabs--;
                //                 printTabs();
                //                 fp << "}" << endl;
                //                 symTabs.pop_table();
                //         }   
                ;
arguments:      ID ':' type     {
                        Trace("Reducing to arguments Form ID ':' type\n");
			variableEntry ve = ve_basic($1.stringVal, $3.tokenType, false);
			ve.isGlobal = false;
			ve.stackIndex = nowStackIndex;
			nowStackIndex++;
			if (!symTabs.addVariable(ve))
				yyerror("Re declaration.");
			symTabs.addArgToPreloadFN($3.tokenType);
		}
		|	arguments ',' ID ':' type     {
			Trace("Reducing to arguments Form arguments ',' ID ':' type\n");
			variableEntry ve = ve_basic($3.stringVal, $5.tokenType, false);
			ve.isGlobal = false;
			ve.stackIndex = nowStackIndex;
			nowStackIndex++;
			if (!symTabs.addVariable(ve))
				yyerror("Re declaration.");
			symTabs.addArgToPreloadFN($5.tokenType);
		}
		|       %empty  { Trace("Reducing to formalArgs Form empty ':' type\n"); }
		;
funcType:       ':' type        {
		 	Trace("Reducing to funcType Form ':' type\n");
			symTabs.addRetToPreloadFN($2.tokenType);
		}
		|	%empty	{ Trace("Reducing to fnType Form empty\n"); }
                ;
subfunc:        KEYWORD_BEGIN   {
                        symTabs.push_table("this");
                }
                statements KEYWORD_END ID ';' {
                        Trace("Reducing to subfunc\n");
                        symTabs.pop_table();
                }      
            ;
statements:     statement   {
                        Trace("Reducing to statements\n");
                }
                |       statements statement     {
                                Trace("Reducing to statement statements\n");
                }
                ;
statement:      ID OPEARATOR_ASSIGIN expression ';' {
                        Trace("Reducing to statement Form ID OPEARATOR_ASSIGIN expression ';\n");

		        variableEntry ve = symTabs.lookup($1.stringVal);
		        if (ve.type == T_404)
		        	yyerror("ID not found");
		        else if (ve.isConst == true)
		        	yyerror("Constant can't be assign");
		        else if (ve.isFn)
		        	yyerror("Function can't be assign");
		        else if (ve.type == T_NONE)
		        	ve.type = $3.tokenType;

		        if (ve.type == T_REAL && $3.tokenType == T_INT)
		        		ve.data.floatVal = $3.intVal;
		        else if (ve.type != $3.tokenType)
		        	yyerror("expression is not equal to expression");
		        else if (ve.type == T_INT)
		        	ve.data.intVal = $3.intVal;
		        else if (ve.type == T_REAL)
		        	ve.data.floatVal = $3.floatVal;
		        else if (ve.type == T_BOOL)
		        	ve.data.boolVal = $3.boolVal;
		        else if (ve.type == T_STRING)
		        	ve.data.stringVal = $3.stringVal;
		        ve.isInit = true;
		        symTabs.editVariable(ve);
		        if (ve.isGlobal)
		        {
		        	printTabs();
				if (ve.type == T_INT)
		        		fp << "putstatic int " << outputfileName << "." << ve.name << endl;
				else if (ve.type == T_REAL)
					fp << "putstatic float " << outputfileName << "." << ve.name << endl;
				else if (ve.type == T_STRING)
					fp << "putstatic java.lang.String " << outputfileName << "." << ve.name << endl;	        	
		        }
		        else
		        {
		        	printTabs();
		        	fp << "istore " << ve.stackIndex << endl;
		        }
                }
        //     |   ID '[' expression ']' OPEARATOR_ASSIGIN expression ';' {
        //             Trace("Reducing to statement\n");
        //     }
                |       KEYWORD_PRINT   {
                                printTabs();
				fp << "getstatic java.io.PrintStream java.lang.System.out" << endl;														
                        } 
                        expression ';'    {
                                Trace("Reducing to statement Form KEYWORD_PRINT expression ';'\n");
				printTabs();
				fp << "invokevirtual void java.io.PrintStream.print(";
				if ($3.tokenType == T_INT)
					fp << "int)" << endl;
				else if ($3.tokenType == T_BOOL)
					fp << "boolean)" << endl;
				else if ($3.tokenType == T_STRING)
					fp << "java.lang.String)" << endl;
				else if ($3.tokenType == T_REAL)
					fp << "float)" << endl;
                        }
                |       KEYWORD_PRINTLN {
                                printTabs();
				fp << "getstatic java.io.PrintStream java.lang.System.out" << endl;
                        } 
                        expression ';'  {
                                Trace("Reducing to statement Form KEYWORD_PRINTLN expression ';'\n");
				printTabs();
				fp << "invokevirtual void java.io.PrintStream.println(";
				if ($3.tokenType == T_INT)
					fp << "int)" << endl;
				else if ($3.tokenType == T_BOOL)
					fp << "boolean)" << endl;
				else if ($3.tokenType == T_STRING)
					fp << "java.lang.String)" << endl;
				else if ($3.tokenType == T_REAL)
					fp << "float)" << endl;
                        }
                // |       KEYWORD_READ expression ';' {
                //                 Trace("Reducing to statement\n");
                // }
                |       KEYWORD_RETURN expression ';'   {
                                Trace("Reducing to statement Form KEYWORD_RETURN expression ';'\n");
		                hasReturned = true;
		                printTabs();
		                fp << "ireturn" << endl;
                        }   
                |       KEYWORD_RETURN ';'      {
                                Trace("Reducing to statement Form KEYWORD_RETURN ';'\n");
		                hasReturned = true;
		                printTabs();
		                fp << "return" << endl;
                        }
                |       ifCon   {
                                Trace("Reducing to statement form ifCon\n");
                        }
                |       loopCon   {
                                Trace("Reducing to statement form loopCon\n");
                        }
                |       funcInvoc ';' {
                                Trace("Reducing to statement form funcInvoc\n");
                        }
                ;
expression:     '-' expression %prec UMINUS {
                        Trace("Reducing to expression Form '-' expression\n");
			$$ = $2;
			if ($$.tokenType == T_INT)
				$$.intVal *= -1;
			else if ($$.tokenType == T_REAL)
				$$.floatVal *= -1;
			else
				yyerror("'-' arg type error.");
                        // fp << nowIsConstant << ' ' << symTabs.isNowGlobal() << endl;
			if (!nowIsConstant && !symTabs.isNowGlobal()) {
			        printTabs();
			        fp << "ineg" << endl;
			}
                }        
                |       expression '+' expression   {
                                Trace("Reducing to expression Form expression '+' expression\n");

				if ($1.notInit)
					yyerror("'+' left arg is not initial.");
				if ($3.notInit)
					yyerror("'+' right arg is not initial.");

				if ($1.tokenType == T_INT && $3.tokenType == T_INT){
					$$.tokenType = T_INT;
					$$.intVal = $1.intVal + $3.intVal;
				}
				else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL){
					$$.tokenType = T_REAL;
					$$.floatVal = $1.floatVal + $3.floatVal;
				}
				else if ($1.tokenType == T_INT && $3.tokenType == T_REAL){
					$$.tokenType = T_REAL;
					$$.floatVal = $1.intVal + $3.floatVal;
				}
				else if ($1.tokenType == T_REAL && $3.tokenType == T_INT){
					$$.tokenType = T_REAL;
					$$.floatVal = $1.floatVal + $3.intVal;
				}
				else
					yyerror("'+' arg type error.");
                               
				if (!nowIsConstant && !symTabs.isNowGlobal()) {
                                        printTabs();
					if ($$.tokenType == T_INT)
                                        	fp << "iadd" << endl;
					else if($$.tokenType == T_REAL)
						fp << "fadd" << endl;
				}
                        }
                |       expression '-' expression   {
                                Trace("Reducing to expression Form expression '-' expression\n");

				if ($1.notInit)
					yyerror("'-' left arg is not initial.");
				if ($3.notInit)
					yyerror("'-' right arg is not initial.");

				if ($1.tokenType == T_INT && $3.tokenType == T_INT){
					$$.tokenType = T_INT;
					$$.intVal = $1.intVal - $3.intVal;
				}
				else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL){
					$$.tokenType = T_REAL;
					$$.floatVal = $1.floatVal - $3.floatVal;
				}
				else if ($1.tokenType == T_INT && $3.tokenType == T_REAL){
					$$.tokenType = T_REAL;
					$$.floatVal = $1.intVal - $3.floatVal;
				}
				else if ($1.tokenType == T_REAL && $3.tokenType == T_INT){
					$$.tokenType = T_REAL;
					$$.floatVal = $1.floatVal - $3.intVal;
				}
				else
					yyerror("'-' arg type error.");
				if (!nowIsConstant && !symTabs.isNowGlobal()) {
					printTabs();
					if ($$.tokenType == T_INT)
                                        	fp << "isub" << endl;
					else if($$.tokenType == T_REAL)
						fp << "fsub" << endl;
				}
                        }
                |       expression '*' expression   {
                                Trace("Reducing to expression Form expression '*' expression\n");

				if ($1.notInit)
					yyerror("'*' left arg is not initial.");
				if ($3.notInit)
					yyerror("'*' right arg is not initial.");

				if ($1.tokenType == T_INT && $3.tokenType == T_INT){
					$$.tokenType = T_INT;
					$$.intVal = $1.intVal * $3.intVal;
				}
				else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL){
					$$.tokenType = T_REAL;
					$$.floatVal = $1.floatVal * $3.floatVal;
				}
				else if ($1.tokenType == T_INT && $3.tokenType == T_REAL){
					$$.tokenType = T_REAL;
					$$.floatVal = $1.intVal * $3.floatVal;
				}
				else if ($1.tokenType == T_REAL && $3.tokenType == T_INT){
					$$.tokenType = T_REAL;
					$$.floatVal = $1.floatVal * $3.intVal;
				}
				else
					yyerror("'*' arg type error.");
				if (!nowIsConstant && !symTabs.isNowGlobal()) {
					printTabs();
					if ($$.tokenType == T_INT)
                                        	fp << "imul" << endl;
					else if($$.tokenType == T_REAL)
						fp << "fmul" << endl;
				}
                        }
                |       expression '/' expression   {
                                Trace("Reducing to expression Form expression '/' expression\n");

				if ($1.notInit)
					yyerror("'/' left arg is not initial.");
				if ($3.notInit)
					yyerror("'/' right arg is not initial.");
				if ($1.tokenType == T_INT && $3.tokenType == T_INT){
					if ($1.intVal != 0){
						$$.tokenType = T_INT;
						$$.intVal = $1.intVal / $3.intVal;
					}
				}	
				// if ($1.tokenType == T_INT && $3.tokenType == T_INT){
				// 	$$.tokenType = T_REAL;
                                //         $$.floatVal = $1.floatVal / $3.floatVal;
				// }
				// else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL){
				// 	$$.tokenType = T_REAL;
				// 	$$.floatVal = $1.floatVal / $3.floatVal;
				// }
				// else if ($1.tokenType == T_INT && $3.tokenType == T_REAL){
				// 	$$.tokenType = T_REAL;
				// 	$$.floatVal = $1.intVal / $3.floatVal;
				// }
				// else if ($1.tokenType == T_REAL && $3.tokenType == T_INT){
				// 	$$.tokenType = T_REAL;
				// 	$$.floatVal = $1.floatVal / $3.intVal;
				// }
				// else
				// 	yyerror("'/' arg type error.");

				if (!nowIsConstant && !symTabs.isNowGlobal()) {
					printTabs();
                                        fp << "idiv" << endl;
				}
                        }        
                |       '(' expression ')'  {
                                Trace("Reducing to '(' expression ')'\n");
                                $$ = $2;
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
                                Trace("Reducing to expression Form functionInvoc\n");
			        if ($1.tokenType == T_NONE)
			        	yyerror("The function no return, can not be expression.");
			        $$.tokenType = $1.tokenType;
                        }
	        |	ID  { 
                                Trace("Reducing to expression Form ID\n");

			        variableEntry ve = symTabs.lookup($1.stringVal);
			        if (ve.type == T_404)
			        	yyerror("ID not found");
			        else if (ve.type == T_NONE)
			        	$$.notInit = true;
			        else if (ve.isArr)
			        	yyerror("Array no give index");
			        else if (ve.isFn)
			        	yyerror("Function no parameters");
			        else
			        {
			        	if (ve.type == T_INT)
			        	{
			        		$$.tokenType = T_INT;
			        		$$.intVal = ve.data.intVal;
			        	}
			        	else if (ve.type == T_REAL)
			        	{
			        		$$.tokenType = T_REAL;
			        		$$.floatVal = ve.data.floatVal;
			        	}
			        	else if (ve.type == T_BOOL)
			        	{
			        		$$.tokenType = T_BOOL;
			        		$$.boolVal = ve.data.boolVal;
			        	}
			        	else if (ve.type == T_STRING)
			        	{
			        		$$.tokenType = T_STRING;
			        		$$.stringVal = ve.data.stringVal;
			        	}
			        }
			        if (ve.isConst)
			        {
			        	printTabs();
			        	if (ve.type == T_INT)
			        		fp << "sipush " << ve.data.intVal << endl;
			        	else if (ve.type == T_BOOL)
			        		fp << "iconst_" << ve.data.boolVal << endl;
			        	else if (ve.type == T_STRING)
			        		fp << "ldc \"" << ve.data.stringVal << "\"" << endl;
			        }
			        else
			        {
			        	if (ve.isGlobal)
			        	{
			        		printTabs();
						if (ve.type == T_INT)
							fp << "getstatic int " << outputfileName << "." << ve.name << endl;
						else if (ve.type == T_REAL)
							fp << "getstatic float " << outputfileName << "." << ve.name << endl;
						else if (ve.type == T_STRING)
							fp << "getstatic java.lang.String " << outputfileName << "." << ve.name << endl;
			        	}
			        	else
			        	{
			        		printTabs();
			        		if (ve.type == T_INT)
			        			fp << "iload " << ve.stackIndex << endl;
			        		else if (ve.type == T_BOOL)
			        			fp << "iload " << ve.stackIndex << endl;
			        	}
			        }
                        }
	        // |	ID '[' integerExpr ']'  { 
                //                 Trace("Reducing to expression\n");
                //         }
	        ;
integerExpr:    INTEGER { 
                        Trace("Reducing to integerExpr Form INTEGER\n");
                        if (!nowIsConstant && !symTabs.isNowGlobal()){
                                printTabs();
                                fp << "sipush " << $1.intVal << endl;
                        }
                }
		;
realExpr:       REAL    { 
                        Trace("Reducing to realExpr Form REAL\n");
			if (!nowIsConstant && !symTabs.isNowGlobal()){
                                printTabs();
                                fp << "ldc " << $1.floatVal << "f" << endl;
                        }
                }
	        ;
boolExpr:       BOOLEAN    {
                        if($1.boolVal == true) {
                                Trace("Reducing to boolExpr form true\n");
                                $$.tokenType = T_BOOL;
				$$.boolVal = true;
				if (!nowIsConstant && !symTabs.isNowGlobal()) 
				{
					printTabs();
					fp << "iconst_1 " << endl;
				}
                        }
                        else {
                                Trace("Reducing to boolExpr form false\n");
                                $$.tokenType = T_BOOL;
				$$.boolVal = false;
				if (!nowIsConstant && !symTabs.isNowGlobal()) 
				{
					printTabs();
					fp << "iconst_0 " << endl;
				}
                        }                
                }
                |       expression '>' expression   {
                                Trace("Reducing to boolExpr Form expression '>' expression\n");

				$$.tokenType = T_BOOL;
				if ($1.notInit)
					yyerror("'>' left arg is not initial.");
				if ($3.notInit)
					yyerror("'>' right arg is not initial.");

				if ($1.tokenType == T_INT && $3.tokenType == T_INT)
					$$.boolVal = $1.intVal > $3.intVal;
				else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL)
					$$.boolVal = $1.floatVal > $3.floatVal;
				else if ($1.tokenType == T_STRING && $3.tokenType == T_STRING)
					$$.boolVal = $1.stringVal > $3.stringVal;
				else
					yyerror("'>' arg type error.");

				printTabs();
				fp << "isub" << endl;
				printTabs();
				fp << "ifgt " << "L" << nowLabelIndex << endl;
				printTabs();
				fp << "iconst_0" << endl;
				printTabs();
				fp << "goto " << "L" << nowLabelIndex + 1 << endl;
				fp << "L" << nowLabelIndex << ":" << endl;
				printTabs();
				fp << "iconst_1" << endl;
				fp << "L" << nowLabelIndex + 1 << ":" << endl;
				nowLabelIndex += 2;
                        }
                |       expression '<' expression   {
                                Trace("Reducing to boolExpr Form expression '<' expression\n");

				$$.tokenType = T_BOOL;
				if ($1.notInit)
					yyerror("'<' left arg is not initial.");
				if ($3.notInit)
					yyerror("'<' right arg is not initial.");
				if ($1.tokenType == T_INT && $3.tokenType == T_INT)
					$$.boolVal = $1.intVal < $3.intVal;
				else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL)
					$$.boolVal = $1.floatVal < $3.floatVal;
				else if ($1.tokenType == T_STRING && $3.tokenType == T_STRING)
					$$.boolVal = $1.stringVal < $3.stringVal;
				else
					yyerror("'<' arg type error.");

				printTabs();
				fp << "isub" << endl;
				printTabs();
				fp << "iflt " << "L" << nowLabelIndex << endl;
				printTabs();
				fp << "iconst_0" << endl;
				printTabs();
				fp << "goto " << "L" << nowLabelIndex + 1 << endl;
				fp << "L" << nowLabelIndex << ":" << endl;
				printTabs();
				fp << "iconst_1" << endl;
				fp << "L" << nowLabelIndex + 1 << ":" << endl;
				nowLabelIndex += 2;
                        }            
                |       expression '=' expression   {
                                Trace("Reducing to boolExpr Form expression '=' expression\n");

			        $$.tokenType = T_BOOL;
			        if ($1.notInit)
			        	yyerror("'=' left arg is not initial.");
			        if ($3.notInit)
			        	yyerror("'=' right arg is not initial.");

			        if ($1.tokenType == T_INT && $3.tokenType == T_INT)
			        	$$.boolVal = $1.intVal == $3.intVal;
			        else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL)
			        	$$.boolVal = $1.floatVal == $3.floatVal;
			        else if ($1.tokenType == T_STRING && $3.tokenType == T_STRING)
			        	$$.boolVal = $1.stringVal == $3.stringVal;
			        else if ($1.tokenType == T_BOOL && $3.tokenType == T_BOOL)
			        	$$.boolVal = $1.boolVal == $3.boolVal;
			        else
			        	yyerror("'=' arg type error.");

			        printTabs();
			        fp << "isub" << endl;
			        printTabs();
			        fp << "ifeq " << "L" << nowLabelIndex << endl;
			        printTabs();
			        fp << "iconst_0" << endl;
			        printTabs();
			        fp << "goto " << "L" << nowLabelIndex + 1 << endl;
			        fp << "L" << nowLabelIndex << ":" << endl;
			        printTabs();
			        fp << "iconst_1" << endl;
			        fp << "L" << nowLabelIndex + 1 << ":" << endl;
			        nowLabelIndex += 2;
                        }
                |       expression OPEARATOR_LESS_EQUAL expression  {
                                Trace("Reducing to boolExpr Form expression OPEARATOR_LESS_EQUAL expression\n");

				$$.tokenType = T_BOOL;
				if ($1.notInit)
					yyerror("'<=' left arg is not initial.");
				if ($3.notInit)
					yyerror("'<=' right arg is not initial.");
				if ($1.tokenType == T_INT && $3.tokenType == T_INT)
					$$.boolVal = $1.intVal <= $3.intVal;
				else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL)
					$$.boolVal = $1.floatVal <= $3.floatVal;
				else if ($1.tokenType == T_STRING && $3.tokenType == T_STRING)
					$$.boolVal = $1.stringVal <= $3.stringVal;
				else
					yyerror("'<=' arg type error.");

				printTabs();
				fp << "isub" << endl;
				printTabs();
				fp << "ifle " << "L" << nowLabelIndex << endl;
				printTabs();
				fp << "iconst_0" << endl;
				printTabs();
				fp << "goto " << "L" << nowLabelIndex + 1 << endl;
				fp << "L" << nowLabelIndex << ":" << endl;
				printTabs();
				fp << "iconst_1" << endl;
				fp << "L" << nowLabelIndex + 1 << ":" << endl;
				nowLabelIndex += 2;
                        }
                |       expression OPEARATOR_MORE_EQUAL expression  {
                                Trace("Reducing to boolExpr Form expression OPEARATOR_MORE_EQUAL expression\n");

				$$.tokenType = T_BOOL;
				if ($1.notInit)
					yyerror("'>=' left arg is not initial.");
				if ($3.notInit)
					yyerror("'>=' right arg is not initial.");

				if ($1.tokenType == T_INT && $3.tokenType == T_INT)
					$$.boolVal = $1.intVal >= $3.intVal;
				else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL)
					$$.boolVal = $1.floatVal >= $3.floatVal;
				else if ($1.tokenType == T_STRING && $3.tokenType == T_STRING)
					$$.boolVal = $1.stringVal >= $3.stringVal;
				else
					yyerror("'>=' arg type error.");

				printTabs();
				fp << "isub" << endl;
				printTabs();
				fp << "ifge " << "L" << nowLabelIndex << endl;
				printTabs();
				fp << "iconst_0" << endl;
				printTabs();
				fp << "goto " << "L" << nowLabelIndex + 1 << endl;
				fp << "L" << nowLabelIndex << ":" << endl;
				printTabs();
				fp << "iconst_1" << endl;
				fp << "L" << nowLabelIndex + 1 << ":" << endl;
				nowLabelIndex += 2;
                        }
                |       expression OPEARATOR_NOT_EQUAL expression   {
                                Trace("Reducing to boolExpr Form expression OPEARATOR_NOT_EQUAL expression\n");

				$$.tokenType = T_BOOL;
				if ($1.notInit)
					yyerror("'<>' left arg is not initial.");
				if ($3.notInit)
					yyerror("'<>' right arg is not initial.");

				if ($1.tokenType == T_INT && $3.tokenType == T_INT)
					$$.boolVal = $1.intVal != $3.intVal;
				else if ($1.tokenType == T_REAL && $3.tokenType == T_REAL)
					$$.boolVal = $1.floatVal != $3.floatVal;
				else if ($1.tokenType == T_STRING && $3.tokenType == T_STRING)
					$$.boolVal = $1.stringVal != $3.stringVal;
				else if ($1.tokenType == T_BOOL && $3.tokenType == T_BOOL)
					$$.boolVal = $1.boolVal != $3.boolVal;
				else
					yyerror("'<>' arg type error.");

				printTabs();
				fp << "isub" << endl;
				printTabs();
				fp << "ifne " << "L" << nowLabelIndex << endl;
				printTabs();
				fp << "iconst_0" << endl;
				printTabs();
				fp << "goto " << "L" << nowLabelIndex + 1 << endl;
				fp << "L" << nowLabelIndex << ":" << endl;
				printTabs();
				fp << "iconst_1" << endl;
				fp << "L" << nowLabelIndex + 1 << ":" << endl;
				nowLabelIndex += 2;
                        }
                |       expression '~' expression   {
                                Trace("Reducing to boolExpr Form expression '~' expression\n");
				if (!($1.tokenType == T_BOOL && $3.tokenType == T_BOOL))
					yyerror("'~' arg type error.");
				$$.tokenType = T_BOOL;
				$$.boolVal = $1.boolVal ^ $3.boolVal;
				if (!nowIsConstant && !symTabs.isNowGlobal()) 
				{
					printTabs();
					fp << "ixor" << endl;
				}
                }
                |       expression OPEARATOR_AND expression {
                                Trace("Reducing to boolExpr Form expression OP_AND expression\n");
				if (!($1.tokenType == T_BOOL && $3.tokenType == T_BOOL))
					yyerror("'&&' arg type error.");
				$$.tokenType = T_BOOL;
				$$.boolVal = $1.boolVal && $3.boolVal;
				if (!nowIsConstant && !symTabs.isNowGlobal()) 
				{
					printTabs();
					fp << "iand" << endl;
				}
                        }
                |       expression OPEARATOR_OR expression  {
                                Trace("Reducing to boolExpr Form boolExpr OP_OR boolExpr\n");
				if (!($1.tokenType == T_BOOL && $3.tokenType == T_BOOL))
					yyerror("'&&' arg type error.");
				$$.tokenType = T_BOOL;
				$$.boolVal = $1.boolVal || $3.boolVal;
				if (!nowIsConstant && !symTabs.isNowGlobal()) 
				{
					printTabs();
					fp << "ior" << endl;
				}
                        }
                ;
stringExpr:     STRING  { 
                        Trace("Reducing to stringExpr Form STRING\n");
                        if (!nowIsConstant && !symTabs.isNowGlobal()) {
				printTabs();
				fp << "ldc \"" << $1.stringVal << "\"" << endl;
			}
                }
        	;
funcInvoc:	ID '(' parameters ')'   { 
		        Trace("Reducing to functionInvoc Form ID '(' parameters ')'\n");
                        
			variableEntry ve = symTabs.lookup($1.stringVal);
			if (ve.type == T_404)
				yyerror("function ID not found");
			$$.tokenType = ve.type;

			printTabs();
			fp << "invokestatic ";
			if (ve.type == T_INT)
				fp << "int ";
			else if (ve.type == T_BOOL)
				fp << "bool ";
			else
				fp << "void ";
			fp << outputfileName << "." << ve.name << "(";
			for (int i = 0; i < ve.argSize; i++)
			{
				if (ve.argType[i] == T_INT)
					fp << "int";
				else if (ve.argType[i] == T_BOOL)
					fp << "bool";
				if (i != ve.argSize - 1)
					fp << ", ";
			}
			fp << ")" << endl;
		}
                ;
parameters:     expression      {
                        Trace("Reducing to parameters\n");
                }
                |       expression ',' parameters       {
                                Trace("Reducing to parameters\n");
                }
                |       %empty  { Trace("Reducing to parameters Form empty\n"); }
                ;
block:  KEYWORD_THEN     {
		symTabs.push_table("this");
	}
	statements      {
		symTabs.pop_table();
	} 
	;
ifCon:  KEYWORD_IF '(' boolExpr ')'     {
                printTabs();
		fp << "ifeq " << "L" << nowLabelIndex << endl;
		topElseLabel.push_back(nowLabelIndex);
		nowLabelIndex++;
        }
        block  elseCon  KEYWORD_END ';' {
                Trace("Reducing to ifStament Form KEYWORD_IF '(' boolExpr ')' KEYWORD_THEN statements elseCon KEYWORD_END ';'\n");
		fp << "L" << topElseLabel.back() << ":" << endl;
		topElseLabel.pop_back();
		printTabs();
		fp << "nop" <<endl;
        }
        ;
elseCon:        KEYWORD_ELSE    {
                        printTabs();
			fp << "goto " << "L" << nowLabelIndex << endl;
			fp << "L" << topElseLabel.back() << ":" << endl;
			topElseLabel.pop_back();
			topElseLabel.push_back(nowLabelIndex);
			nowLabelIndex++;
			printTabs();
			fp << "nop" <<endl;
                        symTabs.push_table("this");
                }
                statements      {
                        symTabs.pop_table();
                }
                |	%empty  { Trace("Reducing to elseStament Form empty\n"); }
                ;
loopCon:        KEYWORD_WHILE   {
                        fp << "L" << nowLabelIndex << ":" << endl;
			$1.beginLabel = nowLabelIndex;
			nowLabelIndex++;
                }
                '(' boolExpr ')'        {
                        printTabs();
			fp << "ifeq " << "L" << nowLabelIndex << endl;
			$1.exitLabel = nowLabelIndex;
			nowLabelIndex++;
                        symTabs.push_table("this");
                } 
                KEYWORD_DO statements KEYWORD_END ';'    {
                        Trace("Reducing to loop Form KW_WHILE '(' boolExpr ')' block\n");
			printTabs();
			fp << "goto " << "L" << $1.beginLabel << endl;
			fp << "L" << $1.exitLabel << ":" << endl;
			printTabs();
			fp << "nop" <<endl;
                        symTabs.pop_table();
                } 
                ;    
%%

int yyerror(const char *s)
{
	fprintf(stderr, "ERROR: %s at line number:%d\n", s, yylineno);
	exit(-1);
	return 0;
}
void printTabs()
{
	for (int i = 0; i < nowTabs; i++)
		fp << "\t";
}
int main(int argc, char *argv[])
{
    // Open srcfile.
	if (argc != 2 && argc !=3)
	{
        fprintf(stderr, "Usage: _rust.exe <filename>\n");
		fprintf(stderr, "Usage: _rust.exe <filename> <outputfileName>\n");
        exit(-1);
    }
	yyin = fopen(argv[1], "r");
	if (!yyin) 
	{
		fprintf(stderr, "ERROR: Fail to open %s\n", argv[1]);
		exit(-1);
	}
	if (argc == 3)
		outputfileName = argv[2];
	// Write jasm.
	fp.open((outputfileName + ".jasm").c_str(), std::ios::out);
    if (!fp) 
	{
		fprintf(stderr, "ERROR: Fail to open %s\n", outputfileName.c_str());
		exit(-1);
	}
	fp << "class " << outputfileName << endl << "{" << endl;
	nowTabs++;
	yyparse();
	fp << "}";
    fp.close();
	return 0;
}