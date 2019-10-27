#!/bin/bash

echo
echo
echo "PREPARING files"
echo
echo

echo "Making /data directory"
mkdir `pwd`/data

echo "Making /results directory"
mkdir `pwd`/results

echo "Making /drugCom_SMH directory"
mkdir `pwd`/drugCom_SMH

echo "Making /data directory"
mkdir `pwd`/history

echo "Making /data directory"
mkdir `pwd`/modelos


echo "Downloading english stopwords"
wget -cO ./data/stopwords_english.txt \
	 https://raw.githubusercontent.com/pan-webis-de/authorid/master/data/stopwords_english.txt


echo "Downloading Drug Review Dataset"
wget -cO drugs_raw.zip \
	 https://archive.ics.uci.edu/ml/machine-learning-databases/00462/drugsCom_raw.zip
unzip -u drugs_raw.zip -d `pwd`/data/raw

echo
echo "Extracting Reviews and Ratings to pickle list:"
python ./python/corpus/extractReviews.py


echo
echo
echo "PREPARING SMH files"
echo
echo



FILE=./data/train_drugReviews.ref
# if [ -f "$FILE" ]; then
# if true ; then
if false ; then
	echo "$FILE exist"
	echo "*SMH .ref and .corpus file generation* block Not marked for processing"
else 

	echo "$FILE does not exist"
	echo "Generating TRAIN Drug Reviews SMH reference text (lemmatized)"
	python python/corpus/reviews2ref.py "/data/raw/drugsComTrain_raw.tsv" "train_drugReviews"

	echo
	echo "Generating TEST Drug Reviews SMH reference text (lemmatized)"
	python python/corpus/reviews2ref.py "/data/raw/drugsComTest_raw.tsv" "test_drugReviews"

	echo
	echo "Generating TRAIN BOWs (.corpus) from drugCom reference text"
	echo
	echo "(We already made sure all corpuses generated use the same vocabulary, the one generated by ALL the train reviews)."
	python python/corpus/ref2corpus.py "./data/train_drugReviews.ref" "./data/stopwords_english.txt" \
				"./data" -c 40000 -voc
	echo "Done with ALL TRAIN reviews."

	python python/corpus/ref2corpus.py "./data/train_drugReviews.ref4train" "./data/stopwords_english.txt" \
				"./data" -c 40000 -nt "4train"
	echo "Done with TRAIN reviews that have a rating."
	echo
	echo
	echo

	echo "Generating TEST BOWs (.corpus) from drugCom reference text"
	python python/corpus/ref2corpus.py "./data/test_drugReviews.ref4train" "./data/stopwords_english.txt" \
				"./data" -c 40000 -nt "4train" 
	# python python/corpus/ref2corpus.py "./data/test_drugReviews.ref" "./data/stopwords_english.txt" \
	#			"./data" -c 40000
	echo "Done."
	echo "We don't generate the corpus of reviews without a rating, because they're not usefull to test the model."

	echo "Genereting TRAIN inverted file from corpus"
	smhcmd ifindex "./data/train_drugReviews40000.corpus" "./data/train_drugReviews40000.ifs"
	# We don't need to get the ifs of the testSet, because we're not finding the topics of the TestSet.

	echo "Done processing drugCom corpus"
	echo
	echo
	echo
fi


echo
echo
echo "DISCOVERING topics"
echo
echo


FILE=./data/train_drugReviews40000.ifs
if [ -f "$FILE" ]; then
# if true ; then
	echo "*Topic Discovering* block Not marked for processing"
else 
	echo
	echo "Discovering SMH topics for drugCom"
	echo
	echo
	python python/discoverTopics/smh_topic_discovery.py \
		--tuple_size 2 \
		--cooccurrence_threshold 0.10 \
		--corpus train_drugReviews40000.corpus \
		--overlap 0.90 \
		--min_set_size 3 \
		./data/train_drugReviews40000.ifs \
		./data/train_drugReviews40000.vocab \
		"./drugCom_SMH"
fi


echo
echo
echo "Ordering topics according to the ammount of documents associated to the topic"
echo "AND creating inverted word:topic file (with the topics reordered)"
echo
echo


FILE=./drugCom_SMH/smh_r2_l68_w0.1_s3_o0.9_m5train_drugReviews40000.IFSwords2topicsOrd
if [ -f "$FILE" ]; then
# if true ; then
# if  false ; then
	echo " *Topics Reordering* block Not marked for processing"
else 
	python python/discoverTopics/topicsReorder.py \
	    "./drugCom_SMH/smh_r2_l68_w0.1_s3_o0.9_m5train_drugReviews40000.models"

	smhcmd ifindex \
		"./drugCom_SMH/smh_r2_l68_w0.1_s3_o0.9_m5train_drugReviews40000.ordered_models" \
		"./drugCom_SMH/smh_r2_l68_w0.1_s3_o0.9_m5train_drugReviews40000.IFSwords2topicsOrd"

fi
echo
echo
echo "mmmmm"
echo
echo

