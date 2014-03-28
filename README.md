Cross Language Relations Spotter
================================

This library can spot cross-language relations.
The library is provided as a JRuby gem, code is available in the directory crosslanguagespotter-gem.

# Example

This example uses data include in the gem, under test/data.

First we need to build a model using a golden set, then we can use the model to recognize cross-language relations.

## Train

First of all you need to train the classifier with a golden set. The golden set has to be manually produced by inspecting similar applications. In the example we provide one, based on an Angular-JS application. We still don't know how generalizable is the classification process: can you train the classifier using a golden-set built on an Angular-JS application and have it work on another kind of application? Maybe, we are trying to understand it.

You train the classifier in this way:

    oracle_loader = OracleLoader.new
    classifier = oracle_loader.build_weka_classifier('./test/data/angular_puzzle','./test/data/angular-puzzle.GS')
    
First you specify a directory where the source code is contained, then the path to the golden set. The golden set contains the positive examples (all the relations present in the project and not in the golden set are considered negative examples). This is one line from the golden set:

    index.html:12:12:puzzleApp:app.js:4:31:puzzleApp
    
It specifies that the element in the file index.html (under the project dir) at line 12, column 12 is related to the element in app.js at line 4 column 31. In both cases the word at that place is "puzzleApp".

## Use the classifier

Ok, now you have a classifier. You can ask it to find the relations in your project by doing:

    spotter = CrossLanguageSpotter::Spotter.new()
    project = Project.new('./test/data/services')
    results = spotter.classify_relations(project,classifier)
    
Results will contain a list of hashes. Here we report some examples:


    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>6, :node_a_end_line=>7,            :node_a_begin_column=>9, :node_a_end_column=>0, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>3, :node_b_end_line=>3, :node_b_begin_column=>11, :node_b_end_column=>15, :shared_length=>0, :tfidf_shared=>0, :itfidf_shared=>0, :perc_shared_length_min=>0.0, :perc_shared_length_max=>0.0, :diff_min=>0, :diff_max=>2, :perc_diff_min=>0.0, :perc_diff_max=>1.0, :context=>0.0, :jaccard=>0.0, :jaro=>0.0, :tversky=>0.0, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>6, :node_a_end_line=>7, :node_a_begin_column=>9, :node_a_end_column=>0, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>4, :node_b_end_line=>4, :node_b_begin_column=>11, :node_b_end_column=>15, :shared_length=>0, :tfidf_shared=>0, :itfidf_shared=>0, :perc_shared_length_min=>0.0, :perc_shared_length_max=>0.0, :diff_min=>0, :diff_max=>2, :perc_diff_min=>0.0, :perc_diff_max=>1.0, :context=>0.0, :jaccard=>0.0, :jaro=>0.0, :tversky=>0.0, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>6, :node_a_end_line=>7, :node_a_begin_column=>9, :node_a_end_column=>0, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>5, :node_b_end_line=>5, :node_b_begin_column=>11, :node_b_end_column=>15, :shared_length=>0, :tfidf_shared=>0, :itfidf_shared=>0, :perc_shared_length_min=>0.0, :perc_shared_length_max=>0.0, :diff_min=>0, :diff_max=>2, :perc_diff_min=>0.0, :perc_diff_max=>1.0, :context=>0.0, :jaccard=>0.0, :jaro=>0.0, :tversky=>0.0, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>6, :node_a_end_line=>7, :node_a_begin_column=>9, :node_a_end_column=>0, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>6, :node_b_end_line=>6, :node_b_begin_column=>11, :node_b_end_column=>15, :shared_length=>0, :tfidf_shared=>0, :itfidf_shared=>0, :perc_shared_length_min=>0.0, :perc_shared_length_max=>0.0, :diff_min=>0, :diff_max=>2, :perc_diff_min=>0.0, :perc_diff_max=>1.0, :context=>0.0, :jaccard=>0.0, :jaro=>0.0, :tversky=>0.0, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>17, :node_a_end_line=>17, :node_a_begin_column=>32, :node_a_end_column=>58, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>1, :node_b_end_line=>15, :node_b_begin_column=>1, :node_b_end_column=>1, :shared_length=>0, :tfidf_shared=>0, :itfidf_shared=>0, :perc_shared_length_min=>0.0, :perc_shared_length_max=>0.0, :diff_min=>0, :diff_max=>2, :perc_diff_min=>0.0, :perc_diff_max=>1.0, :context=>0.6, :jaccard=>0.0, :jaro=>0.0, :tversky=>0.0, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>17, :node_a_end_line=>17, :node_a_begin_column=>32, :node_a_end_column=>58, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>1, :node_b_end_line=>1, :node_b_begin_column=>10, :node_b_end_column=>19, :shared_length=>2, :tfidf_shared=>0.0, :itfidf_shared=>0.0, :perc_shared_length_min=>0.5, :perc_shared_length_max=>1.0, :diff_min=>0, :diff_max=>2, :perc_diff_min=>0.0, :perc_diff_max=>0.5, :context=>0.9999999999999999, :jaccard=>0.5, :jaro=>0.28425229741019215, :tversky=>0.6666666666666666, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>20, :node_a_end_line=>20, :node_a_begin_column=>17, :node_a_end_column=>30, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>2, :node_b_end_line=>2, :node_b_begin_column=>12, :node_b_end_column=>19, :shared_length=>1, :tfidf_shared=>0.0, :itfidf_shared=>0.0, :perc_shared_length_min=>0.5, :perc_shared_length_max=>0.5, :diff_min=>1, :diff_max=>1, :perc_diff_min=>0.5, :perc_diff_max=>0.5, :context=>0.30000000000000004, :jaccard=>0.3333333333333333, :jaro=>0.37222222222222223, :tversky=>0.5, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>20, :node_a_end_line=>20, :node_a_begin_column=>17, :node_a_end_column=>30, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>9, :node_b_end_line=>9, :node_b_begin_column=>32, :node_b_end_column=>39, :shared_length=>1, :tfidf_shared=>0.0, :itfidf_shared=>0.0, :perc_shared_length_min=>0.5, :perc_shared_length_max=>0.5, :diff_min=>1, :diff_max=>1, :perc_diff_min=>0.5, :perc_diff_max=>0.5, :context=>0.30000000000000004, :jaccard=>0.3333333333333333, :jaro=>0.3972222222222222, :tversky=>0.5, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>22, :node_a_end_line=>22, :node_a_begin_column=>43, :node_a_end_column=>50, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>2, :node_b_end_line=>2, :node_b_begin_column=>12, :node_b_end_column=>19, :shared_length=>1, :tfidf_shared=>0.0, :itfidf_shared=>0.0, :perc_shared_length_min=>0.5, :perc_shared_length_max=>0.5, :diff_min=>1, :diff_max=>1, :perc_diff_min=>0.5, :perc_diff_max=>0.5, :context=>0.30000000000000004, :jaccard=>0.3333333333333333, :jaro=>0.37222222222222223, :tversky=>0.5, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>22, :node_a_end_line=>22, :node_a_begin_column=>43, :node_a_end_column=>50, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>9, :node_b_end_line=>9, :node_b_begin_column=>32, :node_b_end_column=>39, :shared_length=>1, :tfidf_shared=>0.0, :itfidf_shared=>0.0, :perc_shared_length_min=>0.5, :perc_shared_length_max=>0.5, :diff_min=>1, :diff_max=>1, :perc_diff_min=>0.5, :perc_diff_max=>0.5, :context=>0.30000000000000004, :jaccard=>0.3333333333333333, :jaro=>0.0, :tversky=>0.5, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>26, :node_a_end_line=>26, :node_a_begin_column=>16, :node_a_end_column=>26, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>7, :node_b_end_line=>7, :node_b_begin_column=>12, :node_b_end_column=>16, :shared_length=>1, :tfidf_shared=>0.0, :itfidf_shared=>0.0, :perc_shared_length_min=>0.5, :perc_shared_length_max=>0.5, :diff_min=>1, :diff_max=>1, :perc_diff_min=>0.5, :perc_diff_max=>0.5, :context=>0.30000000000000004, :jaccard=>0.3333333333333333, :jaro=>0.37564102564102564, :tversky=>0.5, :result=>false}
    {:node_a_file=>"./test/data/services/index.html", :node_a_begin_line=>26, :node_a_end_line=>26, :node_a_begin_column=>43, :node_a_end_column=>47, :node_b_file=>"./test/data/services/script.js", :node_b_begin_line=>7, :node_b_end_line=>7, :node_b_begin_column=>12, :node_b_end_column=>16, :shared_length=>1, :tfidf_shared=>0.0, :itfidf_shared=>0.0, :perc_shared_length_min=>0.5, :perc_shared_length_max=>0.5, :diff_min=>1, :diff_max=>1, :perc_diff_min=>0.5, :perc_diff_max=>0.5, :context=>0.30000000000000004, :jaccard=>0.3333333333333333, :jaro=>0.37564102564102564, :tversky=>0.5, :result=>false}

As you can see the library gives you back the position (file, lines, columns) of the two ends of each relation. You can you use that for cross-language refactoring or to provide tool support. At least, we plan to do that in the future and we would be gladly to get some help!

Status
======

This library is *experimental*: it is an initial attempt to solve a complex issue. Expect all sorts of problems and performance issues. On the other hand we are willing to help you use it, if you feel brave enough!
