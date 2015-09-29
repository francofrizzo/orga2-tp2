all: pdf clean

pdf:
	latexmk -pdf -quiet informe.tex

clean:
	latexmk -c

see: pdf clean
	evince informe.pdf