
%option noyywrap

%{
#include <stdio.h>

#define YY_DECL int yylex()
#include "calc.tab.h"
%}

%%

[ \t]	; // ignore all whitespace
[0-9]+\.[0-9]+ 	{yylval.fval = atof(yytext); return T_FLOAT;}
[0-9]+		{yylval.ival = atoi(yytext); return number;}
[a-f0-9]+"h" {yylval.ival = strtol(yytext, 0, 16); return number;}
"$r"+[A-Z]    {yylval.id = yytext[2]; return identifier;}
"$acc"  {return Answer;}
"showhex"  {return ShowHex;}
"show"  {return Show;}
"load"  {return Load;}
"Push"  {return Push;}
"push"  {return Push;}
"Pop"   {return Pop;}
"pop"   {return Pop;}
"Top"   {return Top;}
"top"   {return Top;}
"size"  {return Size;}
"Size"  {return Size;}
"is"    {return IS;}
([\r\n]+[\t]+)+?[\r\n]+	{return T_NEWLINE;}
"="     {return EQUAL;}
"+"		{return plus;}
"-"		{return minus;}
"*"		{return multiply;}
"/"		{return divide;}
"("		{return left_parenthesis;}
")"		{return right_parenthesis;}
"^"     {return T_RAISED;}
"%"     {return mod;}
"exit"	{return T_QUIT;}
"int"   {return INT;}
"float" {return FLOAT;}
"char"  {return Char;}
"str"   {return Str;}
"quit"	{return T_QUIT;}
"and"    {return AND;}
"or"     {return OR;}
"!"      {return NOT;}
"!="     {return Not_EQUAL;}
"'"      {return Single_Quotes;}
"\""     {return Double_Quotes;}
"loop"   {return For;}
"if"    {return IF;}
">"      {return MoreThan;}
"<"      {return LessThan;}
">="     {return MoreThan_EQUAL;}
"<="     {return LessThan_EQUAL;}
"{"      {return OPENLOOP;}
"}"      {return ENDLOOP;}
"else"   {return ELSE;}      

[a-zA-Z]     {yylval.id= yytext[0]; return Char;}
[a-zA-Z,$+]+ {yylval.s=strdup(yytext); return(String); }

%%