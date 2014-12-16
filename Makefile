lex.yy.c: scanner.flx
	flex scanner.flx
parser.tab.c: parser.y
	bison -d parser.y
parser_data.o: parser_data.c parser_data.h
	gcc -o parser_data.o -c parser_data.c
parser: lex.yy.c parser.tab.c parser_data.o
	gcc -o parser lex.yy.c parser.tab.c parser_data.o -lfl 
clean:
	rm -rf *~ *.out *.o *.tab.* *yy.c parser

