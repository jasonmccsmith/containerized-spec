# FROM python:3.10-slim
FROM texlive/texlive:latest-small AS mdsa-base

# Install necessary build tools and dependencies
RUN apt-get update && apt-get install -y \
  build-essential \
  make \
  git \
  latexmk \
  python3-full \
  python3-pip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN python3 -m venv venv
RUN . venv/bin/activate
ENV PATH="/app/venv/bin:${PATH}"

FROM mdsa-base AS mdsa
# Set working directory (set up user account?)
WORKDIR /app

# Get the necessary LaTeX piece for MDSA templates
RUN tlmgr install everypage draftwatermark svg helvetic xifthen ifmtarg appendix changebar marginnote
RUN tlmgr install changepage
RUN tlmgr install titlesec
RUN tlmgr install soul
RUN tlmgr install todonotes
RUN tlmgr install csquotes
RUN tlmgr install import
RUN tlmgr install courier

# USER ADDED PACKAGES GO HERE - find better way of doing this? Possible to have tlmgr pull from a file of required packages?
# This is until texliveonfly is working with latexmk...

# Install the MDSA core and tools
RUN git clone https://github.com/ObjectManagementGroup/mdsa-tools.git ./mdsa-tools
RUN cd ./mdsa-tools ; pip install -e . ; cd ..
RUN git clone https://github.com/ObjectManagementGroup/mdsa-omg-core.git ./mdsa-omg-core
# Modify _core.mk until we know how this works overall
RUN sed -i 's|-outdir=..|-outdir=${source}|' ./mdsa-omg-core/_core.mk
RUN sed -i 's|cd build \&\& latexmk|cd ${build} \&\& latexmk|g' ./mdsa-omg-core/_core.mk
RUN sed -i 's|_${doc}_Setup.tex|${source}/_${doc}_Setup.tex|g' ./mdsa-omg-core/_core.mk
# RUN sed -i 's|cd build \&\& latexmk|cd build \&\& ls ${source} \&\& echo "---" \&\& ls . \&\& latexmk|' ./mdsa-omg-core/_core.mk
RUN sed -i 's|cp -R ./GeneratedContent "${build}/GeneratedContent"|cp -R ${source}/GeneratedContent "${build}/GeneratedContent"|' ./mdsa-omg-core/_core.mk
RUN sed -i 's|localtex := $(wildcard ./\*.tex) $(wildcard ./\*.bib)|localtex := $(wildcard ${source}/\*.tex) $(wildcard ${source}/\*.bib)|' ./mdsa-omg-core/_core.mk
RUN sed -i 's|markdowns := $(filter-out ./README.md, $(wildcard ./\*.md))|markdowns := $(filter-out ${source}/README.md, $(wildcard ${source}/\*.md))|' ./mdsa-omg-core/_core.mk
RUN sed -i 's|local: $(subst ./,${build}/,${localtex})|local: $(subst ${source}/,${build}/,${localtex})|' ./mdsa-omg-core/_core.mk
RUN sed -i 's|md: ${build} $(subst ./,${build}/,$(subst .md,.tex,${markdowns}))|md: ${build} $(subst ${source}/,${build}/,$(subst .md,.tex,${markdowns}))|' ./mdsa-omg-core/_core.mk
RUN sed -i 's|imagefiles := $(subst ./,${build}/,$(wildcard ./Images/\*.svg))|imagefiles := $(subst ${source}/,${build}/,$(wildcard ${source}/Images/\*.svg))|' ./mdsa-omg-core/_core.mk
RUN sed -i 's|: \./|: ${source}/|g' ./mdsa-omg-core/_core.mk
RUN sed -i 's|rm -rf build/|rm -rf ${build}/|' ./mdsa-omg-core/_core.mk

# Set up latexmk / texliveonfly integration
RUN <<EOF > /app/.latexmkrc
# $pdflatex = 'texliveonfly %O %S';  # Use texliveonfly for LaTeX compilation
# $latex = 'texliveonfly %O %S';  # Use texliveonfly for LaTeX compilation
# $pdf = 'texliveonfly %O %S';  # Use texliveonfly for LaTeX compilation
# $commands = 1;
# $diagnostics = 1;
$pdf_mode = 1;  # Set to 1 for PDF output
$bibtex_use = 1;
$out_dir = '/source';
$aux_dir = '.';
EOF

# Default command
# ENTRYPOINT ["cat", "./mdsa-omg-core/_core.mk"]
ENTRYPOINT ["make", "-f", "/source/Makefile"]
