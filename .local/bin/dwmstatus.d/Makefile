
in = dwmstatus.c
out = dwmstatus
libs = -lX11
end = $(libs) $(in) -o $(out)
installdir = ~/.local/bin

prod = -Ofast
dbg  = -ggdb

dwmstatus: dwmstatus.c
	clang $(prod) $(end)

debug: dwmstatus.c
	clang $(dbg) $(end)

.PHONY: install
install:
	[ -e ./$(out) ] && [ -d $(installdir) ] && mv $(out) $(installdir)

.PHONY: clean
clean:
	@rm dwmstatus
