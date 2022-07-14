#! /bin/bash

build=0
cleanup=0
full=0
update=0

function usage {
    
    echo " "
    echo "usage: $0 [-b][-c][-f][-u]"
    echo " "
    echo "    -b          just build DentPath ontology extension"
    echo "    -c          cleanup temporary output files"
    echo "    -f          build DentPath ontology extension and include the RDFBones core ontology"
    echo "    -u          initiate and update submodules if they are not up to date"
    echo "    -h -?       print this help"
    echo " "

    exit

}



while getopts "bcfuh?" opt; do

    case "$opt" in

	b)
	    build=1
	    ;;

	c)
	    cleanup=1
	    ;;

	f)
	    full=1
	    ;;

	u)
	    update=1
	    ;;

	?)
	    usage
	    ;;
	
	h)
	    usage
	    ;;

    esac

done


## SUBMODULES
#############

## Check if submodules are initialised

if [ $update -eq 1 ];then

    git submodule init
    git submodule update
    
fi

if [ $build -eq 1 ] || [ $full -eq 1 ]; then

    ## Delete Output Files From Previous Versions

    rm -r results/*

    ## BUILD DEPENDENCIES
    #####################

    ## RDFBones CORE ONTOLOGY

    cd RDFBones-O/robot/
    
    ./Script-Build_RDFBones-Robot.sh

    cd ../..

    ## BUILD ONTOLOGY EXTENSION
    ###########################

    ## Build Template

    robot template --input RDFBones-O/robot/results/rdfbones.owl \
	  --template Template_DentPath.tsv \
	  --prefix "dentpath: http://w3id.org/rdfbones/ext/dentpath/" \
	  --prefix "obo: http://purl.obolibrary.org/obo/" \
	  --prefix "rdfbones: http://w3id.org/rdfbones/core#" \
	  --ontology-iri "http://w3id.org/rdfbones/ext/dentpath/latest/dentpath.owl" \
	  --output results/dentpath.owl

    ## Quality Test of Output

    robot reason --reasoner ELK \
	  --input results/dentpath.owl \
	  -D results/dentpath-debug.owl

    robot annotate  --input results/dentpath.owl \
	  --remove-annotations \
	  --ontology-iri "http://w3id.org/rdfbones/ext/dentpath/latest/dentpath.owl" \
	  --version-iri "http://w3id.org/rdfbones/ext/dentpath/v0-1/dentpath.owl" \
    	  --annotation dc:creator "Felix Engel" \
    	  --annotation dc:creator "Stefan Schlager" \
    	  --annotation owl:versionInfo "0.1" \
    	  --language-annotation dc:description "This RDFBones ontology extension implements 'Dental Pathology: Methods for Reconstructing Dietary Patterns' by John R. Lukacs, chapter 14 of 'Reconstruction of Life From the Skeleton' edited. by Mehmet Yasar Iscan and Kenneth A. R. Kennedy and published in 1989." en \
    	  --language-annotation rdfs:label "Dental Pathologies" en \
    	  --language-annotation rdfs:comment "Reference: Lukasc, John. R. (1989). Dental Pathology: Methods for Reconstructing Dietary Patterns. In Iscan, M. Y., & Kennedy, A. R. (Eds.). Reconstruction of Life From the Skeleton (pp. 261-286). New York: Liss." en \
	  --output results/dentpath.owl
    

fi

## PREPARE OUTPUT
#################

if [ $full -eq 1 ];then

    robot merge --input RDFBones-O/robot/results/rdfbones.owl \
	  --input results/dentpath.owl \
	  --output results/dentpath_ext_core.owl

    robot annotate --input results/dentpath_ext_core.owl \
	  --remove-annotations \
	  --ontology-iri "http://w3id.org/rdfbones/core/latest/rdfbones.owl" \
	  --language-annotation dc:description "This is the RDFBones core ontology and the DentPath ontology extension merged together." en \
	  --language-annotation rdfs:label "RDFBones core ontology and DentPath extension" en \
	  --language-annotation rdfs:comment "CAUTION: This is not a properly curated ontology. Use for testing purposes only! For productivity, obtain separate versions of the core ontology and ontology extensions." en \
	  --output results/dentpath_ext_core.owl
	  

    if [ $cleanup -eq 1 ] && [ $build -eq 0 ];then

	rm results/dentpath.owl

    fi

fi
