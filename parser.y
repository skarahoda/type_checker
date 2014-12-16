%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser_data.h"
#include "parser.tab.h"

parser_info_t	parser_info = { NULL, 0, 0};

void yyerror(const char *s) {/* Called by yyparse on error*/
	printf("%s\n",s);
	parser_info.counter++;
}

char * type_to_string(int type)
{
	switch(type)
	{
	case BOOLEAN:		case STATIC(BOOLEAN):	return "bool";
	case INT:		case STATIC(INT):	return "int";
	case REAL:		case STATIC(REAL):	return "real";
	case ARRAY(BOOLEAN):				return "bool array";
	case ARRAY(INT):				return "int array";
	case ARRAY(REAL):				return "real array";
	default: return "UNKNOWN";
	}
}
void check_assgn(int line, int l, int r)
{
	if(r != -1 && l!=r && l!=r-6)
	{
		printf("ERROR at line%d: type mismatch between %s and %s\n"
			,line 
			,type_to_string(l)
			,type_to_string(r));
		parser_info.counter++;
	}
	
}
void check_conditonal(int line, int type, int is_if)
{
	if(type != -1 && type != BOOLEAN && type != STATIC(BOOLEAN))
	{
		printf("ERROR at line%d: %s statement have %s expresion expected boolean.\n",
			line
			,is_if ? "if" : "while"
			,type_to_string(type));
		parser_info.counter++;
	}
		
}
void check_array(token_int_t * lval, token_str_t * variable, token_int_t * expr)
{
	lval->line = variable->line;
	lval->type = get_type(variable->id,&parser_info) - 3;
	if(lval->type < 0 || lval->type > 2)
	{
		printf("ERROR at line%d: %s is not an array\n",variable->line, variable->id);
		lval->type += 3; // error recovery assume lvalue is an array
		parser_info.counter++;
	}
	if(expr->type != -1 && expr->type != INT && expr->type != STATIC(INT))
	{
		printf("ERROR at line%d: index of array is %s not an integer\n"
			,variable->line
			,type_to_string(expr->type));
		parser_info.counter++;
		return;
	}
	if(expr->type == STATIC(INT) && (expr->val < 1 || expr->val > get_size(variable->id,&parser_info)))
	{
		printf("ERROR at line%d:array index is out of bound.\n",variable->line);
		parser_info.counter++;
	}
}
void execute_binary_op(token_int_t * production,token_int_t * left,token_int_t * op ,token_int_t * right)
{
	production->line = left->line;
	if(-1 == left->type || -1 == right->type)
	{
		production->type = -1;
		return;
	}
	switch((int)op->val)
	{
	case tAND:
		production->type = BOOLEAN;
		if(BOOLEAN != left->type && STATIC(BOOLEAN) != left->type)
		{
			printf("ERROR at line %d: %s expresion should be boolean \n",left->line, type_to_string(left->type));
			production->type = -1;
			parser_info.counter++;
		}
		if(BOOLEAN != right->type && STATIC(BOOLEAN) != right->type)
		{
			printf("ERROR at line %d: %s expresion should be boolean \n",right->line, type_to_string(right->type));
			production->type = -1;
			parser_info.counter++;
		}
		return;
	case tEQ:
		production->type = BOOLEAN;
		if((BOOLEAN == left->type || STATIC(BOOLEAN) == left->type) && (BOOLEAN == right->type || STATIC(BOOLEAN) == right->type))
			return;
	case tLESS:
		production->type = BOOLEAN;
		if((INT == left->type || STATIC(INT) == left->type) && (INT == right->type || STATIC(INT) == right->type))
			return;
		if((REAL == left->type || STATIC(REAL) == left->type) && (REAL == right->type || STATIC(REAL) == right->type))
			return;
		production->type = -1;
		printf("ERROR at line %d: type mismatch on expresions near the \"%s\" operation.\n", op->line, op->val == tLESS ? "<" : "==");
		parser_info.counter++;
		break;
	case tPLUS:
	case tSTAR:
		if((INT == left->type || STATIC(INT) == left->type) && (INT == right->type || STATIC(INT) == right->type))
		{
			if(STATIC(INT) == left->type && STATIC(INT) == right->type)
			{
				production->type = STATIC(INT);
				if(tSTAR == op->val)
					production->val = (int)left->val * (int)right->val;
				else
					production->val = (int)left->val + (int)right->val;
				return;
			} 
			production->type = INT;
			return;
		}
		production->type = REAL;
		if(BOOLEAN == left->type || STATIC(BOOLEAN) == left->type || (2 < left->type && 6 > left->type))
		{
			printf("ERROR at line %d: Expresion cannot be boolean or array. Found: %s.\n",left->line, type_to_string(left->type));
			parser_info.counter++;
			production->type = -1;
		} 
		if(BOOLEAN == right->type || STATIC(BOOLEAN) == right->type || (2 < right->type && 6 > right->type))
		{
			printf("ERROR at line %d: Expresion cannot be boolean or array. Found: %s\n",right->line, type_to_string(right->type));
			parser_info.counter++;
			production->type = -1;
		}
		if(-1 == production->type)
			return;
		if((STATIC(INT) == left->type || STATIC(REAL) == left->type) && (STATIC(INT) == right->type || STATIC(REAL) == right->type))
		{
			production->type = STATIC(REAL);
			if(STATIC(INT) == right->type)
			{
				if(tSTAR == op->val)
					production->val = left->val * (int)right->val;
				else
					production->val = left->val + (int)right->val;
			}
			else if(STATIC(INT) == left->type)
			{
				if(tSTAR == op->val)
					production->val = (int)left->val * right->val;
				else
					production->val = (int)left->val + right->val;
			}
			else
			{
				if(tSTAR == op->val)
					production->val = left->val * right->val;
				else
					production->val = left->val + right->val;
			}
			return;
		}
		return; 
	default:
	printf("ERROR at line %d: UNKNOWN operation\n",production->line);
	parser_info.counter++;
	}
}
void execute_unary_op(token_int_t * production,token_int_t * expr,int op)
{
	production->line = expr->line;
	production->type = expr->type;
	if(-1 == expr->type)
	{
		return;
	}
	if(op == tNOT)
	{
		if(BOOLEAN != expr->type && STATIC(BOOLEAN) != expr->type)
		{
			printf("ERROR at line %d: %s expresion should be boolean.\n",expr->line, type_to_string(expr->type));
			parser_info.counter++;
			production->type = -1;
		}
		return;
	}
	//if minus operator
	if(2 < expr->type && 6 > expr->type)
	{
		printf("ERROR at line %d: %s expresion cannot be an array.\n",expr->line, type_to_string(expr->type));
		parser_info.counter++;
		production->type = -1;
	}
}
%}

%union 
{
	int line;
	token_int_t my_int;
	token_str_t my_str;
}

%token <line> tFALSE tTRUE tINT tREAL tBOOLEAN tBEGIN tEND tIF tTHEN tELSE tSEMI tASSIGN tLPAREN tRPAREN tLBRACKET tRBRACKET tPLUS tSTAR tLESS tEQ tAND tMINUS tNOT tWHILE
%token <my_str> tID
%token <my_int> tINTNUM tREALNUM
%type <my_int> Type Lval Expr BinOp
%type <line> UnOp
%start Prgrm

%left tAND
%left tEQ
%left tLESS
%left tPLUS
%left tSTAR
%left tMINUS
%left tNOT
%%
Prgrm:		  VarDeclLst StmtBlk
VarDeclLst:	  VarDecl VarDeclLst
		| VarDecl
VarDecl:	  Type tID tSEMI					{ add_to_list($2.id,$1.type,-1, &parser_info);			}
		| Type tID tLBRACKET tINTNUM tRBRACKET tSEMI		{ add_to_list($2.id,$1.type, $4.val, &parser_info);		}
Type:		  tINT 							{ $$.type = INT;	$$.line = $1;				}
		| tREAL							{ $$.type = REAL;	$$.line = $1;				}
		| tBOOLEAN						{ $$.type = BOOLEAN;	$$.line = $1;				}
StmtBlk:	  tBEGIN StmtLst tEND
StmtLst:	  Stmt StmtLst
		| Stmt
Stmt:		  AssgnStmt
		| IfStmt
		| WhlStmt
AssgnStmt:	  Lval tASSIGN Expr tSEMI				{ check_assgn($1.line,$1.type,$3.type);				}
Lval:		  tID							{ $$.line = $1.line;	$$.type = get_type($1.id,&parser_info);	}
		| tID tLBRACKET Expr tRBRACKET				{ check_array(&$$, &$1, &$3);					}
IfStmt:		  tIF tLPAREN Expr tRPAREN tTHEN StmtBlk tELSE StmtBlk	{ check_conditonal($3.line,$3.type,1);				}
WhlStmt:	  tWHILE tLPAREN Expr tRPAREN StmtBlk			{ check_conditonal($3.line,$3.type,0);				}
Expr:		  tINTNUM						{$$.line = $1.line; $$.type = STATIC(INT); $$.val = $1.val; 	}
		| tREALNUM						{$$.line = $1.line; $$.type = STATIC(REAL); $$.val = $1.val;	}
		| tFALSE						{$$.line = $1;	$$.type = STATIC(BOOLEAN); 			}
		| tTRUE							{$$.line = $1;	$$.type = STATIC(BOOLEAN); 			}
		| tID							{ $$.line = $1.line;	$$.type = get_type($1.id,&parser_info);	}
		| tID tLBRACKET Expr tRBRACKET				{ check_array(&$$, &$1, &$3);					}
		| tLPAREN Expr tRBRACKET				{$$.line = $2.line; $$.type = $2.type;				}
		| Expr BinOp Expr					{execute_binary_op(&$$,&$1,&$2,&$3);				}
		| UnOp Expr						{execute_unary_op(&$$,&$2,$1);					}
BinOp:		  tPLUS							{$$.val = tPLUS;	$$.line = $1;				}
		| tSTAR							{$$.val = tSTAR;	$$.line = $1;				}
		| tLESS							{$$.val = tLESS;	$$.line = $1;				}
		| tEQ							{$$.val = tEQ;		$$.line = $1;				}
		| tAND							{$$.val = tAND;		$$.line = $1;				}
UnOp:		  tMINUS						{$$ = tMINUS;							}
		| tNOT							{$$ = tNOT;							}
%%

int main()
{
	if(yyparse() || parser_info.counter > 0)
	{
		printf("=========================================================\n");
		if(parser_info.counter == 1)
			printf("So close. There is an error.\n");
		else
			printf("There are %d errors\n",parser_info.counter);
		return 1;
	}
	else
	{
		printf("OK\n");
		return 0;
	}
}
