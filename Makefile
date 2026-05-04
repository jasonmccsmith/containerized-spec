###
# Build specification docs
#

### Setup
# There is very little to set up to run the containerized version of MDSA.
#
# If you wish to change either the location of generated content from a model, or the name of the resulting PDF,
# edit the appropriate values in Makefile.docker (gencondir, pdfnamebase). The rest should be left alone.
#
# If you need to add LaTeX packages, add them one per line to the user-pkgs.txt file, and they will be incorporated
# into your next build.

### Basic use: 'make'
# If a Docker image has not yet been built, that will be done first, then the processing of the LaTeX will begin.
# The resulting PDF (and only that file) will be placed in this directory.
#
### Debugging: `make debug`
# This will show the output of the LaTeX build to help debug.
#
### Using pandoc for Markdown
# To use a pandoc based workflow, use 'make pandoc' and 'make pandoc-debug' 
#

all: run
.PHONY: all

build: image=omg/mdsa
build: Dockerfile
	docker build -t omg/mdsa --file Dockerfile .

build-pandoc: image="omg/mdsa-pandoc"
build-pandoc: Dockerfile.pandoc
	docker build -t omg/mdsa-pandoc --file Dockerfile.pandoc .

run: build
	docker run --rm -v "${CURDIR}:/source" omg/mdsa

debug: build
	docker run --rm -v "${CURDIR}:/source" omg/mdsa debug

clean:
	docker rmi omg/mdsa

pandoc: build-pandoc gen
	docker run --rm -v "${CURDIR}:/source" omg/mdsa-pandoc

debug-pandoc: build-pandoc
	docker run --rm -v "${CURDIR}:/source" omg/mdsa-pandoc debug

clean-pandoc:
	docker rmi omg/mdsa-pandoc

### Generating from a model
# If a file named <SPECACRO>.config is present in this directory, it will be used to drive md2LaTeX.py from the mdsa-tools
# repository, and generate LaTeX files from a MagicDraw model. (Other tool support pending.) Otherwise, this step
# is skipped.

# Where you GeneratedContent will be placed from your model if you're using that mechanism
gencondir := GeneratedContent

# Only generate from the model if there is an appropriate ${specacro}.config file. I.e. UML.config or BPMN.config.
gen: ${gencondir}
	@echo --- Generating from model
	@if [ -f "${specacro}.config" ]; then \
		./mdsa-tools/omgmdsa/md2LaTeX.py --config "${specacro}.config"; \
	else \
		echo "[MDSA] No "${specacro}.config" file, not building from model"; \
	fi

${gencondir}:
	mkdir -p "${gencondir}"
