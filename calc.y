
%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
extern FILE* yyin;
struct node{
	char *data;
	struct node* next;
};
typedef struct node node;
node* getnode(char *data,node* next)
{
	node *p=(node*)malloc(sizeof(node));
	char *new_string = (char *)malloc(strlen(data) + 1); 
	strcpy(new_string,data);
	p->data=new_string;
	p->next=next;
return p;
}
void append(char *s,node* t)
{
	while(t->next != NULL)
	{
		t = t->next;
	}
	node *p=getnode(s,NULL);
	t->next = p;
	t = t -> next;
}
void newJump(int jump,node* t)
{
	while(t->next != NULL)
	{
		t = t->next;
	}
	char temp[100];
	sprintf(temp,".L%d",jump);
	node *p=getnode(temp,NULL);
	t->next = p;
	t = t -> next;
}
node *code;
node *data;
node *jump;
int answer = 0;
int countdata = 0;
int top =0;
int size =0;
int last_count_byte =0;
int num =0;
char a = '0';
bool checkJump = false;
int jumppoint = 1;
int count_byte = 0;
bool checkString = false;
int  reg[100] ;
char regChar[100];
char *regString[100];
float regFloat[100];
int regByte[100];
int type[100] ;
int stack[100];
bool checkBool = false;
bool checkRegEqual(char a,char b);
void yyerror(const char* s);
int getAnswer();
int getRegValue(char c);
int LoadValue(char c,int number);
void LoadValueChar(char c,char assgin);
void LoadValueString(char c,char *s);
int LoadReg(char c1,char c2);
int showRegister(char c);
int PushStack(int number);
int PopStack(char c);
int PushStackReg(int c);
int LoadValueNum(char c,int number);
void ChangeString(char *s);
%}

%union {
	char* s;
	int ival;
	float fval;
	char id;
}

%token<ival> number IF For
%token<fval> T_FLOAT
%token<ival> identifier
%token<id> Answer 
%token<s> String
%token<id> Show Load Push Pop Top Size Char ShowHex
%token plus minus multiply divide left_parenthesis right_parenthesis IS  INT FLOAT  Str OPENLOOP ENDLOOP
%token T_NEWLINE T_QUIT Single_Quotes Double_Quotes  MoreThan MoreThan_EQUAL LessThan LessThan_EQUAL ELSE
%left_parenthesis AND OR NOT EQUAL Not_EQUAL
%left_parenthesis plus minus
%left_parenthesis multiply divide mod
%right T_RAISED

%type<ival> expression
%type<fval> mixed_expression
%type<ival> assginValue
%type<ival> Condition
%type<ival> Loop

%start calculation

%%

calculation: 
	   | calculation line
;

line: T_NEWLINE
    	| Show mixed_expression T_NEWLINE 								
	{ 	
		printf("%f\n", $2);
	}

    	| Show expression T_NEWLINE 									
	{ 	
		printf("%i\n",$2); 	
		char temp[100];
		sprintf(temp,".LC%d",countdata);
		append(temp,data);
		append("\t.string %d",data);
		sprintf(temp,"\tmov     esi, %d",$2);
		append(temp,code);
		sprintf(temp,"\tmov     edi, OFFSET FLAT:.LC%d",countdata);
		append(temp,code);
		append("\tcall    printf",code);
		countdata = countdata +1;
	} 

	| ShowHex expression T_NEWLINE									
	{ 
		printf("%x\n",$2);
		char temp[100];
		sprintf(temp,".LC%d",countdata);
		append(temp,data);
		append("\t.string %x",data);
		sprintf(temp,"\tmov     esi, %d",$2);
		append(temp,code);
		sprintf(temp,"\tmov     edi, OFFSET FLAT:.LC%d",countdata);
		append(temp,code);
		append("\tcall    printf",code);
		countdata = countdata +1;
	}

	| T_QUIT T_NEWLINE 												
	{ 
		printf("bye!\n"); exit(0);

	}

	| Show identifier  T_NEWLINE									
	{ 
		showRegister($2);
	}

	| identifier IS  identifier  T_NEWLINE  						
	{ 
		LoadReg($1,$3);
	}

	| Show Double_Quotes String Double_Quotes T_NEWLINE				
	{ 
		ChangeString($3); 
		if(checkString == false){
			char temp[100];
			sprintf(temp,".LC%d",countdata);
			append(temp,data);
			sprintf(temp,"\t.string %s",$3);
			append(temp,data);
			sprintf(temp,"\tmov     edi, OFFSET FLAT:.LC%d",countdata);
			append(temp,code);
			append("\tcall    printf",code);
			countdata = countdata +1;
		}
	}

	| Show Single_Quotes Char Single_Quotes T_NEWLINE				
	{ 
		printf("%c\n",$3);
		char temp[100];
		sprintf(temp,"\tmov     edi,%d",$3);
		append(temp,code);
		append("\tcall    putchar",code);
	}

	| Condition

	| Loop

	| identifier IS expression T_NEWLINE					     
	{ 
		type[$1] = 1;LoadValue($1,$3);
		if(count_byte == 0)
		{
			regByte[$1] = 4;
			char temp[100];
			sprintf(temp,"\tmov     DWORD PTR [rbp-%d], %d",regByte[$1],$3);
			append(temp,code);
			count_byte = 4;
		}
		else
		{
			regByte[$1] = ((count_byte%4)+2)*4;
			char temp[100];
			sprintf(temp,"\tmov     DWORD PTR [rbp-%d], %d",regByte[$1],$3);
			append(temp,code);
			count_byte = regByte[$1];
		}
	}

	| identifier IS Single_Quotes Char Single_Quotes T_NEWLINE	 
	{
		type[$1] = 2;LoadValueChar($1,$4);
		if(count_byte == 0)
		{
			regByte[$1] = 1;
			char temp[100];
			sprintf(temp,"\tmov     BYTE PTR [rbp-%d], %d",regByte[$1],$4);
			append(temp,code);
			count_byte = 1;
		}
		else
		{
			regByte[$1] = count_byte+1;
			char temp[100];
			sprintf(temp,"\tmov     BYTE PTR [rbp-%d], %d",regByte[$1],$4);
			append(temp,code);
			count_byte  = regByte[$1];
		}	
	}

	| identifier IS Double_Quotes String Double_Quotes T_NEWLINE 
	{
		type[$1] = 3;LoadValueString($1,$4);
		if(count_byte == 0)
		{
			regByte[$1] = 8;
			char temp[100];
			sprintf(temp,"\tmov     BYTE PTR [rbp-%d], %d",regByte[$1],$4);
			append(temp,code);
			count_byte = 1;
		}
		else
		{
			regByte[$1] = (abs(count_byte-8)+1)*8;
			char temp[100];
			sprintf(temp,"\tmovs     BYTE PTR [rbp-%d], %d",regByte[$1],$4);
			append(temp,code);
			count_byte  = regByte[$1];
		}	
	}	

	| identifier IS assginValue 							
	{ 	
		type[$1] = 1;
		regByte[$1] = num;
		reg[$1] = $3;
	}	
;

mixed_expression: T_FLOAT                 			 
	{ $$ = $1; }
	  | mixed_expression plus mixed_expression	 	{ $$ = $1 + $3; }
	  | mixed_expression minus mixed_expression	 	{ $$ = $1 - $3; }
	  | mixed_expression multiply mixed_expression 	{ $$ = $1 * $3; }
	  | mixed_expression divide mixed_expression	 	{ $$ = $1 / $3; }
	  | mixed_expression T_RAISED mixed_expression   	{ $$ = pow ($1, $3);}
	  | mixed_expression mod	mixed_expression	{ $$ = fmod($1,$3);}
	  | left_parenthesis mixed_expression right_parenthesis		 	{ $$ = $2; }
	  | expression T_RAISED mixed_expression         	{ $$ = pow ($1, $3);}
	  | expression plus mixed_expression	 	     	{ $$ = $1 + $3; }
	  | expression minus mixed_expression	 	     	{ $$ = $1 - $3; }
	  | expression multiply mixed_expression 	     	{ $$ = $1 * $3; }
	  | expression divide mixed_expression	    	{ $$ = $1 / $3; }
	  | expression mod mixed_expression		    	{ $$ = fmod($1,$3);}
	  | mixed_expression plus expression	 	    	{ $$ = $1 + $3; }
	  | mixed_expression minus expression	 	    	{ $$ = $1 - $3; }
	  | mixed_expression multiply expression 	   	{ $$ = $1 * $3; }
	  | mixed_expression divide expression	   	{ $$ = $1 / $3; }
	  | mixed_expression T_RAISED expression       		{ $$ = pow ($1, $3);}
	  | mixed_expression mod expression		   	{ $$ = fmod($1,$3);}
	  | expression divide expression		 	{ $$ = $1 / (float)$3; }
;




assginValue: identifier 
	{ 
		if(type[$1] == 1){
			$$ = getRegValue($1);
			last_count_byte = regByte[$1];
		}
		else{printf("ERROR Not math type\n");} 
	}
	| assginValue plus assginValue  	
	{ 
		$$ = $1 + $3;
		num = ((count_byte%4)+2)*4;
		char temp[100];
		append("\tmov     eax, DWORD PTR [rbp]",code);
		append("\tmov     edx, DWORD PTR [rbp]",code);
		append("\tlea     eax, [rdx+rax]",code);
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d]",num);
		append(temp,code);
		count_byte = num;
	}
	| assginValue plus expression		
	{ 
		$$ = $1 + $3;
		num = ((count_byte%4)+2)*4;
		char temp[100];
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d]",last_count_byte);
		append(temp,code);
		sprintf(temp,"\tadd     eax,%d",$3);
		append(temp,code);
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d], eax",num);
		append(temp,code);
		count_byte = num;
	}
	| assginValue minus assginValue  	
	{ 	$$ = $1 - $3;
		num = ((count_byte%4)+2)*4;
		char temp[100];
		append("\tmov     eax, DWORD PTR [rbp]",code);
		append("\tmov     edx, DWORD PTR [rbp]",code);
		append("\tmov     ecx, edx",code);
		append("\tsub     ecx, eax",code);
		append("\tmov     eax, ecx",code);
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d], eax",num);
		append(temp,code);
		count_byte = num;
	}
	| assginValue minus expression 
	{ 
		$$ = $1-$3;
		num = ((count_byte%4)+2)*4;
		char temp[100];
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d]",last_count_byte);
		append(temp,code);
		sprintf(temp,"\tsub     eax,%d",$3);
		append(temp,code);
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d], eax",num);
		append(temp,code);
		count_byte = num;
	}
	| assginValue multiply assginValue  
	{ 
		$$ = $1 * $3;
		num = ((count_byte%4)+2)*4;
		char temp[100];
		append("\tmov     eax, DWORD PTR [rbp]",code);
		append("\timul    eax, DWORD PTR [rbp]",code);								
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d],eax",num);
		append(temp,code);
		count_byte = num;
	}
	| assginValue multiply expression  
	{ 
		$$ = $1 * $3;
		num = ((count_byte%4)+2)*4;
		char temp[100];
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d]",last_count_byte);
		append(temp,code);
		append("\tmov     eax, edx",code);
		append("\tsal     eax, 2",code);
		append("\tadd     eax, edx",code);
		append("\tadd     eax, eax",code);
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d], eax",num);
		append(temp,code);
		count_byte = num;
	}
	| assginValue divide assginValue    
	{ 
		$$ = $1 / $3;
		num = ((count_byte%4)+2)*4;
		char temp[100];
		append("\tmov     eax, DWORD PTR [rbp]",code);
		append("\tmov     edx, eax",code);
		append("\t sar     edx, 31",code);
		append("\tidiv    eax, DWORD PTR [rbp]",code);								
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d],eax",num);
		append(temp,code);
		count_byte = num;
	}
	| assginValue divide expression		
	{ 
		$$ = $1/$3;
		num = ((count_byte%4)+2)*4;
		char temp[100];
		sprintf(temp,"\tmov     eax,DWORD PTR [rbp-%d]",last_count_byte);
		append(temp,code);
		append("\tmov     edx, eax",code);
		append("\tshr     edx, 31",code);
		append("\tlea      eax, [rdx+rax]",code);
		append("\tsar      eax",code);
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d], eax",num);
		append(temp,code);
		count_byte = num;
	  
	}
	| assginValue mod assginValue    	
	{ 	$$ = fmod($1 ,$3);
		num = ((count_byte%4)+2)*4;
		char temp[100];
		append("\tmov     eax, DWORD PTR [rbp]",code);
		append("\tmov     edx, eax",code);
		append("\t sar     edx, 31",code);
		append("\tidiv    eax, DWORD PTR [rbp]",code);								
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d],eax",num);
		append(temp,code);
		count_byte = num;
	}
	| assginValue mod expression    	
	{ 
		$$ = fmod($1 ,$3);
		num = ((count_byte%4)+2)*4;
		char temp[100];
		sprintf(temp,"\tmov     eax,DWORD PTR [rbp-%d]",last_count_byte);
		append(temp,code);
		append("\tmov     edx, eax",code);
		append("\tsar     edx, 31",code);
		append("\tshr     edx, 31",code);
		append("\tadd     eax, edx",code);
		append("\tand     eax, 1",code);
		append("\tsub     eax, edx",code);
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d], eax",num);
		append(temp,code);
		count_byte = num;
	}
	| assginValue T_RAISED assginValue    
	{ 
		$$ = pow($1 ,$3);
		num = ((count_byte%4)+2)*4;
		char temp[100];
		append("\tmov     eax, DWORD PTR [rbp]",code);
		append("\tmov     edx, DWORD PTR [rbp]",code);
		append("\txor     eax, edx",code);								
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d],eax",num);
		append(temp,code);
		count_byte = num;
	}
	| left_parenthesis assginValue right_parenthesis		 	
	{ 
		$$ = $2; 
	}	 
;


expression: number				{ $$ = $1; }
	  | expression plus expression	{ $$ = $1 + $3; }
	  | expression minus expression	{ $$ = $1 - $3; }
	  | expression multiply expression	{ $$ = $1 * $3; }
	  | left_parenthesis expression right_parenthesis		{ $$ = $2; }
	  | expression T_RAISED expression  	{ $$ = pow ($1, $3); }
	  | expression mod expression     	{ $$ = fmod($1,$3);}
	  | minus expression 			{ $$ = -$2;}
	  | expression AND expression		{ $$ = $1 && $3;}
	  | expression OR expression 		{ $$ = $1 || $3;}
	  | NOT expression			{ $$ = !$2;}
;

Condition: IF							
	{ $$ = $1;}
	| IF Condition_stage T_NEWLINE OPENLOOP T_NEWLINE Show Double_Quotes String Double_Quotes T_NEWLINE  ENDLOOP 			
	{
		if(checkBool)
		{ 
			printf("%s\n",$8); 
		}
		char temp[100];
		sprintf(temp,".LC%d",countdata);
		append(temp,data);
		sprintf(temp,"\t.string %s",$8);
		append(temp,data);
		sprintf(temp,"\tmov     edi, OFFSET FLAT:.LC%d",countdata);
		append(temp,code);
		append("\tcall    printf",code);
		jumppoint = jumppoint +1;
		sprintf(temp,".L%d:",jumppoint);
		append(temp,code);
		countdata = countdata +1;
	}  
	| IF Condition_stage T_NEWLINE OPENLOOP T_NEWLINE Show Double_Quotes String Double_Quotes T_NEWLINE  ENDLOOP ELSE T_NEWLINE OPENLOOP T_NEWLINE Show Double_Quotes String Double_Quotes T_NEWLINE ENDLOOP										 	
	{
		if(checkBool)
		{ 
			printf("%s\n",$8);
		}
		char temp[100];
		sprintf(temp,".LC%d",countdata);
		append(temp,data);
		sprintf(temp,"\t.string %s",$8);
		append(temp,data);
		sprintf(temp,"\tmov     edi, OFFSET FLAT:.LC%d",countdata);
		append(temp,code);
		append("\tcall    printf",code);
		jumppoint = jumppoint+2;
		sprintf(temp,"\tjmp     .L%d",jumppoint);
		append(temp,code);
		countdata = countdata +1;
		sprintf(temp,".LC%d",countdata);
		append(temp,data);
		sprintf(temp,"\t.string %s",$18);
		append(temp,data);
		sprintf(temp,".L%d",jumppoint-1);
		append(temp,code);
		sprintf(temp,"\tmov     edi, OFFSET FLAT:.LC%d",countdata);
		append(temp,code);
		append("\tmov     eax, 0",code);
		append("\tcall    printf",code);
		newJump(jumppoint,code);
		countdata = countdata +1;
	}  	  
	| IF Condition_stage T_NEWLINE OPENLOOP T_NEWLINE identifier IS expression  T_NEWLINE ENDLOOP 			
	{
		if(checkBool)
		{
			type[$6] = 1;LoadValue($6,$8);
		}
	}
	| IF Condition_stage T_NEWLINE OPENLOOP T_NEWLINE identifier IS Char  T_NEWLINE ENDLOOP 				
	{
		if(checkBool)
		{
			type[$6] = 2;LoadValueChar($6,$8);
		}
	}
	| IF Condition_stage T_NEWLINE OPENLOOP T_NEWLINE identifier IS String  T_NEWLINE ENDLOOP 				
	{
		if(checkBool)
		{
			type[$6] = 3;LoadValueString($6,$8);
		}
	}
	| IF Condition_stage T_NEWLINE OPENLOOP T_NEWLINE expression T_NEWLINE ENDLOOP 						
	{
		if(checkBool){$6;}
	}
;

Loop:For identifier LessThan expression expression T_NEWLINE  OPENLOOP  T_NEWLINE Show String T_NEWLINE  ENDLOOP						
	{
		int start = reg[$2];
		for(start;start<$4;start=start+$5)
		{
			printf("%s\n",$10);
		}
	}
	|For identifier LessThan expression expression T_NEWLINE  OPENLOOP  T_NEWLINE Show String T_NEWLINE For identifier LessThan expression expression T_NEWLINE  OPENLOOP  T_NEWLINE Show String T_NEWLINE  ENDLOOP T_NEWLINE ENDLOOP 
	{ 
		int start = reg[$2];
		for(start;start<$4;start=start+$5)
		{
			printf("%s\n",$10);
			for(int i=0;i<$15;i=i+$16)
			{
				printf("%s\n",$21);
			}
		}
	}
;


Condition_stage: expression EQUAL expression				
	{
		if($1 == $3)
		{ 
			checkBool = true;
		}
	}
	| expression Not_EQUAL expression						
	{
		if($1 != $3)
		{ 
			checkBool = true;
		}
	}
	| expression MoreThan expression						
	{
		if($1 > $3)
		{ 
			checkBool = true;
		}
	}
	| expression MoreThan_EQUAL expression				
	{
		if($1 >= $3)
		{ 
			checkBool = true;
		}
	}
	| expression LessThan expression						
	{
		if($1 < $3)
		{ 
			checkBool = true;
		}
	}
	| identifier EQUAL expression							
	{
		if(type[$1] == 1)
		{
			if(reg[$1] == $3)
			{ 
				checkBool = true;}
		  		char temp[100];
				sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$1],$3);
				append(temp,code);
				sprintf(temp,"\tjne     .L%d",jumppoint+1);
				append(temp,code);
			} 
		else
		{
			printf("ERROR Not math type\n");
		}
	}
	| identifier Not_EQUAL expression						
	{
		if(type[$1] == 1)
		{
			if(reg[$1] != $3)
			{ 
				checkBool = true;
			}
  			char temp[100];
			sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$1],$3);
			append(temp,code);
			sprintf(temp,"\tjne     .L%d",jumppoint+1);
			append(temp,code);
	  	}
		else
		{
			printf("ERROR Not math type\n");
		}
	}
	| identifier MoreThan expression						
	{
		if(type[$1] == 1)
		{
			if(reg[$1] > $3)
			{ 
				checkBool = true;}
	  			char temp[100];
				sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$1],$3);
				append(temp,code);
				sprintf(temp,"\tjne     .L%d",jumppoint+1);
				append(temp,code);
	  	}
		else
		{
			printf("ERROR Not math type\n");
		}
	}
	| identifier MoreThan_EQUAL expression				{if(type[$1] == 1){if(reg[$1] >= $3){ checkBool = true;}
	  			char temp[100];
				sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$1],$3-1);
				append(temp,code);
				sprintf(temp,"\tjne     .L%d",jumppoint+1);
				append(temp,code);
	  }else{printf("ERROR Not math type\n");}}
	  | identifier LessThan expression						{if(type[$1] == 1){if(reg[$1] < $3){ checkBool = true;}
	  			char temp[100];
				sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$1],$3-1);
				append(temp,code);
				sprintf(temp,"\tjne     .L%d",jumppoint+1);
				append(temp,code);
	  }else{printf("ERROR Not math type\n");}}
	| identifier LessThan_EQUAL expression						{if(type[$1] == 1){if(reg[$1] <= $3){ checkBool = true;}
	  			char temp[100];
				sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$1],$3);
				append(temp,code);
				sprintf(temp,"\tjne     .L%d",jumppoint+1);
				append(temp,code);
	  }else{printf("ERROR Not math type\n");}}
	  | identifier EQUAL identifier						{if(type[$1] == type[$3])
	  {if(checkRegEqual($1,$3)){ checkBool = true;
	  			char temp[100];
				sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$1]);
				append(temp,code);
				sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$3]);
				append(temp,code);
				sprintf(temp,"\tjne     .L%d",jumppoint+1);
				append(temp,code);

	  }

	  }else{printf("ERROR Not math type\n");}}
	  | identifier Not_EQUAL identifier						
	  	{if(type[$1] == type[$3])
		  {
			  if(checkRegEqual($1,$3))
		  		 checkBool = false;
				   else
				   checkBool =true;
				   char temp[100];
					sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$1]);
					append(temp,code);
					sprintf(temp,"\tcmp     DWORD PTR [rbp-%d],%d",regByte[$3]);
					append(temp,code);
					append("\tje     .L2",code);

			  }
			  else
			  {	printf("ERROR Not math type\n");
			  	}
			  }
	  | identifier EQUAL Char								{if(type[$1] == 2){if(regChar[$1] == $3){ checkBool = true;}}else{printf("ERROR Not math type\n");}}
	  | identifier Not_EQUAL Char							{if(type[$1] == 2){if(regChar[$1] != $3){ checkBool = true;}}else{printf("ERROR Not math type\n");}}
	  | identifier EQUAL String								{if(type[$1] == 3){if(!strcmp(regString[$1], $3)){ checkBool = true;}}else{printf("ERROR Not math type\n");}}
	  | identifier Not_EQUAL String							{if(type[$1] == 3){if(strcmp(regString[$1], $3)){ checkBool = false;}else{ checkBool = true;}}else{printf("ERROR Not math type\n");}}
	  ;
	  
%%
int updateAnswer(int number)
{
	answer = number;
}

int LoadValue(char c,int number)
{	
	
	reg[c] = number;
	
	return 0;
}

void LoadValueChar(char c,char assgin)
{
	regChar[c] = assgin;

}

void LoadValueString(char c,char *s)
{
	regString[c] = s;
}



int LoadReg(char c1,char c2)
{
	type[c1] == type[c2];
	if(type[c1] == 1)
	{
		reg[c1] = reg[c2];
		char temp[100];
		sprintf(temp,"\tmov     eax, DWORD PTR [rbp-%d]",regByte[c2]);
		append(temp,code);
		regByte[c1] = ((count_byte%4)+2)*4;
		sprintf(temp,"\tmov     DWORD PTR [rbp-%d], eax",regByte[c1]);
	    append(temp,code);
		count_byte = regByte[c1];

	}
	else if(type[c1] == 2)
	{
		regChar[c1] = regChar[c2];
		char temp[100];
		sprintf(temp,"\tmov     eax, BYTE PTR [rbp-%d]",regByte[c2]);
		append(temp,code);
		regByte[c1] = count_byte+1;
		sprintf(temp,"\tmov     BYTE PTR [rbp-%d], eax",regByte[c1]);
	    append(temp,code);
		count_byte = regByte[c1];

	}
	else if(type[c1] == 3)
	{
		regString[c2] = regString[c1];
		char temp[100];
		sprintf(temp,"\tmov     rax, QWORD PTR [rbp-%d]",regByte[c2]);
		append(temp,code);
		regByte[c1] = (abs(count_byte-8)+1)*8;
		sprintf(temp,"\tmov     QWORD PTR [rbp-%d], eax",regByte[c1]);
	    append(temp,code);
		count_byte = regByte[c1];
	}

	return 0;
}

int PushStack(int number)
{
	if(top == 99)
	{
		printf("stack is full\n");
	}
	else
	{
	printf("%d\n",number);
	top=top+1;
	size=size+1;
	stack[top] = number;
	return 0;
	}
}

int PopStack(char c)
{
	if(top > -1)
	{
		reg[c] = stack[top];
		top = top-1;
		size = size-1;
	}
	else
	{
		printf("!   ERROR");
	}
	return 0;

}

bool checkRegEqual(char a,char b)
{
	if(type[a] == 1)
	{
		if(reg[a] == reg[b])
			return true;
	}
	if(type[a] == 2)
	{
		if(regChar[a] == regChar[b])
			return true;
	}
	if(type[a] == 3)
	{
		if(strcmp(regString[a],regString[b]))
			return false;
			else
			return true;
	}
	return false;

}
int PushStackReg(int c)
{
	printf("see %d\n",c);
}

int getRegValue(char c)
{
	if(type[c] == 1)
	{
		return reg[c];
	}

	return 0;

}

int showRegister(char c)
{
	if(type[c] == 1)
	{
		printf(" %d\n",reg[c]);
		
			char temp[100];
			sprintf(temp,".LC%d",countdata);
			append(temp,data);
			append("\t.string %d",data);
			sprintf(temp,"\tmov     eax, DWORD PTR [rbp-%d]",regByte[c]);
			append(temp,code);
			append("\tmov     esi, eax",code);
			sprintf(temp,"\tmov     edi, OFFSET FLAT:.LC%d",countdata);
			append(temp,code);
			append("\tmov     eax, 0",code);
			append("\tcall    printf",code);
	

	}
	else if(type[c] == 2)
	{
		printf("= %c\n",regChar[c]);
		char temp[100];
		sprintf(temp,"\tmovsx     eax,BYTE PTR [rbp-%d], %d",regByte[c]);
		append(temp,code);
		append("\tmov     edi, eax",code);
		append("\tcall    putchar",code);
	}
	else if(type[c] == 3)
	{
			
	
			char temp[100];
			sprintf(temp,".LC%s",countdata);
			append(temp,data);
			append("\t.string %d",data);
			sprintf(temp,"\tmov     eax, QWORD PTR [rbp-%d]",regByte[c]);
			append(temp,code);
			append("\tmov    	rsi, rax",code);
			sprintf(temp,"\tmov     edi, OFFSET FLAT:.LC%d",countdata);
			append(temp,code);
			append("\tmov     eax, 0",code);
			append("\tcall    printf",code);

	}
	else if(type[c] == 4)
	{
		printf("= %f\n",regFloat[c]);
	}
	else 
	printf("Error the register is NULL\n");
	

	return 0;
}
void ChangeString(char *s)
{
	int count = strlen(s);
	int i = 0;
	while(i<= count-1)
	{
		if((s[i] == '$') && (s[i+1] == 'n' ))
		{
			checkString = true;
			s[i] = ' ';
			s[i+1] = '\n';
		}
		i++;
	}
	printf("%s\n",s);
	if(checkString){
					int i = 0;
				while(i<= count-1)
				{
					if((s[i] == '$') && (s[i+1] == 'n' ))
					{
						s[i] = ' ';
						s[i+1] = ' ';
					}
					i++;
				}
		
			char temp[100];
			sprintf(temp,".LC%d",countdata);
			append(temp,data);
			sprintf(temp,"\t.string %s",s);
			append(temp,data);
			sprintf(temp,"\tmov     edi, OFFSET FLAT:.LC%d",countdata);
			append(temp,code);
			append("\tcall    put",code);
			countdata = countdata +1;

	}

}
void print(node* p)
{
	if(p)
	{
		printf("%s\n",p->data);
		print(p->next);
	}


}



int main(int argc, const char *argv[]) {

	for(int i=0;i<98;i++)
	{
		reg[i] = 0;
		type[i] = 0;
		regByte[i] =0;
	}
	data = getnode(" ",NULL);
	code = getnode(".LBB2:",NULL);
	jump = getnode(".L2:",NULL);
	node *j3 = getnode(".L3",NULL);
printf("%s\n", argv[1]);
    yyin = fopen(argv[1], "r");

    if(yyin == NULL){
        printf("invalid input file\n");
        exit(1);
    }
	do { 
		yyparse();
	} while(!feof(yyin));
	node *head = getnode(".Ldebug_abbrev0:",NULL);
	node *h = head;
	node *t = head;
	append(".Ldebug_info0:",t);
	append(".Ldebug_line0:",t);
	append(".Ltext0:",t);
	append("main:",t);
	append(".LFB0:",t);
	append("\tpush    rbp",t);
	append(".LCFI0:",t);
	append("\tmov     rbp, rsp",t);
	print(data);
	print(code);

	

	return 0;
}
void yyerror(const char* s) {
	fprintf(stderr, "Syntax error \n");
}
