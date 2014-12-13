%{
#include <stdio.h>

void yyerror(const char *s) {/* Called by yyparse on error*/
	printf("%s\n",s);
}
%}

%token tFALSE tTRUE tINT tREAL tBOOLEAN tBEGIN tEND tIF tTHEN tELSE tSEMI tASSIGN tLPAREN tRPAREN tLBRACKET tRBRACKET tPLUS tSTAR tLESS tEQ tAND tMINUS tNOT tINTNUM tREALNUM tID tWHILE
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
VarDecl:	  Type tID tSEMI
		| Type tID tLBRACKET tINTNUM tRBRACKET tSEMI
Type:		  tINT 
		| tREAL
		| tBOOLEAN
StmtBlk:	  tBEGIN StmtLst tEND
StmtLst:	  Stmt StmtLst
		| Stmt
Stmt:		  AssgnStmt
		| IfStmt
		| WhlStmt
AssgnStmt:	  Lval tASSIGN Expr tSEMI
Lval:		  tID
		| tID tLBRACKET Expr tRBRACKET
IfStmt:		  tIF tLPAREN Expr tRPAREN tTHEN StmtBlk tELSE StmtBlk
WhlStmt:	  tWHILE tLBRACKET Expr tRBRACKET StmtBlk
Expr:		  tINTNUM
		| tREALNUM
		| tFALSE
		| tTRUE
		| tID
		| tID tLBRACKET Expr tRBRACKET
		| tLPAREN Expr tRBRACKET
		| Expr BinOp Expr
		| UnOp Expr
BinOp:		  tPLUS
		| tSTAR
		| tLESS
		| tEQ
		| tAND
UnOp:		  tMINUS
		| tNOT
%%

int main()
{
	if(yyparse())
	{
		printf("ERROR\n");
		return 1;
	}
	else
	{
		printf("OK\n");
		return 0;
	}
}
