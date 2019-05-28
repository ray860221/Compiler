%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
#include "s_table.h"

#define LIST    strcat(buf,yytext)

#ifdef LEX_PRINT
#define token(t)        {                               \
                        LIST;                           \
                        printf("<%s>\n", yytext);       \
                        return t;                       \
                        }
#define tokenType(type, val)    {                                       \
                                LIST;                                   \
                                printf("<%s: %s>\n", #type, val);       \
                                return type;                             \
                                }

#define tokenStr(val)   {                                               \
                        LIST;                                           \
                        printf("<%s: %s>\n", "STRING", str_buf);        \
                        str_buf[0] = '\0';                              \
                        BEGIN(INITIAL);                                 \
                        return STRING;                                  \
                        }
#else
#define token(t)        {                               \
                        LIST;                           \
                        return t;                       \
                        }
#define tokenType(type, val)    {                                       \
                                LIST;                                   \
                                return type;                             \
                                }

#define tokenStr(val)   {                                               \
                        LIST;                                           \
                        str_buf[0] = '\0';                              \
                        BEGIN(INITIAL);                                 \
                        return STRING;                                  \
                        }
#endif

#define MAX_LINE_LENG 1024

extern "C"{
        extern int yywarp();
        extern int yylex();

}

int com_line = 0;
char buf[MAX_LINE_LENG];
char str_buf[MAX_LINE_LENG];

%}

number [0-9]+
identifier [a-zA-Z0-9]+
boolean "false"|"true"
realnum [0-9]+.[0-9]+

%x IN_STRING
%x IN_COMMENT
%x IN_LINECOMMENT
             
%%

","             {token(',');}
":"             {token(':');}
";"             {token(';');}
"."             {token('.');}
"("             {token('(');}
")"             {token(')');}
"{"             {token('{');}
"}"             {token('}');}
"["             {token('[');}
"]"             {token(']');}

"+"             {token('+');}
"-"             {token('-');}
"*"             {token('*');}
"/"             {token('/');}
"%"             {token('%');}
"<"             {token('<');}
"<="            {token(OPEARATOR_LESS_EQUAL);}
">"             {token('>');}
">="            {token(OPEARATOR_MORE_EQUAL);}
"="             {token('=');}
"<>"            {token(OPEARATOR_NOT_EQUAL);}
"&&"            {token(OPEARATOR_AND);}
"||"            {token(OPEARATOR_OR);}
"~"             {token('~');}
":="            {token(OPEARATOR_ASSIGIN);}

"array"         {token(KEYWORD_ARRAY);}
"boolean"       {token(KEYWORD_BOOLEAN);}
"begin"         {token(KEYWORD_BEGIN);}
"break"         {token(KEYWORD_BREAK);}
"char"          {token(KEYWORD_CHAR);}
"case"          {token(KEYWORD_CASE);}
"const"         {token(KEYWORD_CONST);}
"continue"      {token(KEYWORD_CONTINUE);}        
"do"            {token(KEYWORD_DO);}
"else"          {token(KEYWORD_ELSE);}
"end"           {token(KEYWORD_END);}
"exit"          {token(KEYWORD_EXIT);}
"false"         {token(KEYWORD_FALSE);}
"for"           {token(KEYWORD_FOR);}
"fn"            {token(KEYWORD_FN);}
"if"            {token(KEYWORD_IF);}
"in"            {token(KEYWORD_IN);}
"integer"       {token(KEYWORD_INTEGER);}        
"loop"          {token(KEYWORD_LOOP);}
"module"        {token(KEYWORD_MODULE);}        
"print"         {token(KEYWORD_PRINT);}
"println"       {token(KEYWORD_PRINTLN);}        
"procedure"     {token(KEYWORD_PROCEDURE);}        
"repeat"        {token(KEYWORD_REPEAT);}        
"return"        {token(KEYWORD_RETURN);}        
"real"          {token(KEYWORD_REAL);}
"string"        {token(KEYWORD_STRING);}        
"record"        {token(KEYWORD_RECORD);}        
"then"          {token(KEYWORD_THEN);}
"ture"          {token(KEYWORD_TURE);}
"type"          {token(KEYWORD_TYPE);}
"use"           {token(KEYWORD_USE);}
"util"          {token(KEYWORD_UTIL);}
"var"           {token(KEYWORD_VAR);}
"while"         {token(KEYWORD_WHILE);}

{number}	{
                yylval.Token.tokenType = T_INT;
                yylval.Token.intVal = atoi(yytext);
                tokenType(INTEGER, yytext);
		}
{realnum}	{
                yylval.Token.tokenType = T_REAL;
                yylval.Token.floatVal = atof(yytext);
                tokenType(REAL, yytext);
		}
{boolean}       {
                tokenType(BOOLEAN, yytext);
                }
        
"\""      {
        LIST;
        BEGIN(IN_STRING);
        }                
<IN_STRING>\"   {
                yylval.Token.tokenType = T_STRING;
                yylval.Token.stringVal = strdup(str_buf);
                tokenStr(str_buf);
                }
<IN_STRING>\n   {
                LIST;
                printf("<%d: %s>", yylineno++, buf);
                buf[0] = '\0';
                strcat(str_buf, "\n");
                }
<IN_STRING>\"\" {
                LIST;
                strcat(str_buf, "\"");
                }


{identifier}	{
                yylval.Token.stringVal = strdup(yytext);
                tokenType(ID, yytext);            
		}

"//"    {
        LIST;
        char x, set[1];  
        while((x = yyinput()) != '\n'){
                set[0] = x;
                strcat(buf, set);
        }
        printf("%d: %s\n", yylineno++, buf);
        buf[0] = '\0';
        }

"(*"    {
        LIST;
        char x, set[1];  
        while(x = yyinput()){
                if (x == '\n'){
                        printf("%d: %s\n", yylineno++, buf);
                        buf[0] = '\0';  
        }
                else if (x == ')'){
                        set[0] = x;
                        strcat(buf, set); 
                        if ((x = yyinput()) == '\n'){
                                printf("%d: %s\n", yylineno++, buf);
                                buf[0] = '\0';
                                break;
                        }
                }
                else{
                        set[0] = x;
                        strcat(buf, set); 
                }
        }
        }

\n      {
        LIST;
        printf("%d: %s", yylineno++, buf);
        buf[0] = '\0';
        }

[ \t]*  {LIST;} 

.       {
        LIST;
        printf("%d: %s", yylineno, buf);
        printf("bad character:'%s'\n", yytext);
        exit(-1);
        }

%%
int yywrap()
{
        printf("%-4d:%s\n", yylineno, buf);
        if(str_buf[0] != '\0')
        {
                printf("unterminated double quote string error\n");
                exit(0);
        }
        return 1;
}