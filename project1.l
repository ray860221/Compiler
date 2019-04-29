%{
#include <stdio.h>
#include <string.h>
#define LIST     strcat(buf,yytext)
#define token(t) {LIST; printf("<'%s'>\n",t);}
#define keywords(t) {LIST;}

#define MAX_LINE_LENG 256

int linenum = 1;
char buf[MAX_LINE_LENG];
char str_buf[MAX_LINE_LENG];
char table[20][20];

void create(){
        for(int i = 0; i < 20 ;i++)
                table[i][0] = '\0';
}
void insert(char* a){
        for(int i = 0; i < 20 ;i++){
                if (table[i][0] == '\0'){
                        for(int j = 0; j < strlen(a); j++)
                                table[i][j] = a[j];
                        break;
                }
        }
}
int lookup(char* a){
        int cmp_result;
        for(int i = 0; i < 20 ;i++){
                cmp_result = strcmp(table[i], a);
                if (cmp_result == 0)
                        return -1;
        }
        return 1;
}
void dump(){
        for(int i = 0; i < 20 ;i++)
                table[i][0] = '\0';
} 
%}

number [0-9]+
identifier [a-zA-Z0-9]+
boolean "false"|"true"
realnum [0-9]+.[0-9]+

deli ","|":"|";"|"."|"("|")"|"{"|"}"|"["|"]"
operator "+"|"-"|"*"|"/"|"%"|"<"|"<="|">"|">="|"=="|"<>"|"&&"|"||"|"~"|":"|"="
keyword "array"|"boolean"|"begin"|"break"|"char"|"case"|"const"|"continue"|"do"|"else"|"end"|"exit"|"false"|"for"|"fn"|"if"|"in"|"integer"|"ioop"|"module"|"print"|"println"|"procedure"|"repeat"|"return"|"real"|"string"|"record"|"then"|"ture"|"type"|"use"|"util"|"var"|"while"
             
%%

{deli}          {token(yytext);}
{operator}	{token(yytext);}
{keyword}	{
                LIST;
                for(int i = 0; i < strlen(yytext); i++){
                        if(yytext[i] >= 97)
                                yytext[i] -= 32;      
                }
                printf("<%s>\n",yytext);
                }
{realnum}	{
                LIST;
                printf("<float: %f>\n", atof(yytext));
		}
{number}	{
                LIST;
                printf("<int: %d>\n", atoi(yytext));
		}
{boolean}       {
                LIST;
                printf("<bool: %s>\n", yytext);
                }
{identifier}	{
                LIST;
                printf("<id: %s>\n", yytext);
                if (lookup(yytext) != -1){
                        insert(yytext);
                }               
		}

"//"    {
        LIST;
        char x, set[1];  
        while((x = input()) != '\n'){
                set[0] = x;
                strcat(buf, set);
        }
        printf("%d: %s\n", linenum++, buf);
        buf[0] = '\0';
        }

"(*"    {
        LIST;
        char x, set[1];  
        while(x = input()){
                if (x == '\n'){
                        printf("%d: %s\n", linenum++, buf);
                        buf[0] = '\0';  
        }
                else if (x == ')'){
                        set[0] = x;
                        strcat(buf, set); 
                        if ((x = input()) == '\n'){
                                printf("%d: %s\n", linenum++, buf);
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

"\""	{
        LIST;		
        char x, set[1];
        while((x = input()) != '\"'){
                set[0] = x;
                strcat(buf, set);
                strcat(str_buf, set);
        }
        set[0] = x;
        strcat(buf, set);
        printf("<string: %s>\n",str_buf);	
	}

\n      {
        LIST;
        printf("%d: %s", linenum++, buf);
        buf[0] = '\0';
        }

[ \t]*  {LIST;} 

.       {
        LIST;
        printf("%d: %s", linenum, buf);
        printf("bad character:'%s'\n", yytext);
        exit(-1);
        }

%%
int main(){
	yylex();
        printf("\nSymbol Table\n----------------------\n");
        for(int i = 0; i < 20 ;i++){
                if(table[i][0] != '\0')
                        printf("%s\n", table[i]);
        }
}