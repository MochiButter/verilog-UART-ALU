.PHONY: pdf view clean

pdf: notes.pdf
notes.pdf: notes.md metadata.md
	pandoc -f markdown -t pdf --metadata-file metadata.md notes.md -o notes.pdf

view: notes.pdf
	evince $<

clean:
	rm ./report.pdf
