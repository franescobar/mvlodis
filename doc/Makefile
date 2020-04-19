SRCDIR = .
AUXDIR = .

output:
	@make clean
	@latexmk -pdf $(SRCDIR)/main
	@make clean

clean:
	@-rm $(AUXDIR)/*.aux $(AUXDIR)/*.log $(AUXDIR)/*.bbl $(AUXDIR)/*.blg $(AUXDIR)/*.bcf $(AUXDIR)/*.nlo $(AUXDIR)/*.out $(AUXDIR)/*.xml $(AUXDIR)/*.lof $(AUXDIR)/*.lot $(AUXDIR)/*.toc $(AUXDIR)/*.ver $(AUXDIR)/*.hst $(AUXDIR)/*.fdb_latexmk $(AUXDIR)/*.fls $(AUXDIR)/*.nav $(AUXDIR)/*.snm $(AUXDIR)/*.vrb $(AUXDIR)/X.tex $(AUXDIR)/*.auxlock
