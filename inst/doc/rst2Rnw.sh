rst2latex sas7bdat.rst > sas7bdat.tex
sed -re '/^%%% User specified packages and stylesheets/a \
    \\usepackage{fullpage}\
    \\usepackage{Sweave}\
    %\\VignetteIndexEntry{sas7bdat}' sas7bdat.tex > sas7bdat.Rnw
rm sas7bdat.tex
