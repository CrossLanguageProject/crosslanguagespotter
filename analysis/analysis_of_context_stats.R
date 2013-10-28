## In this file we perform some simple analysis on features derived from
## the context, to look into the importance of each feature and decide
## which ones to include in the classification algorithm

data = read.csv('stats_on_context.csv')
pos.data = data[data$class=='true',]
neg.data = data[data$class=='false',]

# Boxplots
boxplot(pos.data$shared_length,neg.data$shared_length)
boxplot(pos.data$tfidf_shared,neg.data$tfidf_shared)
boxplot(pos.data$itfidf_shared,neg.data$itfidf_shared)
boxplot(pos.data$perc_shared_length_min,neg.data$perc_shared_length_min)
boxplot(pos.data$perc_shared_length_max,neg.data$perc_shared_length_max)
boxplot(pos.data$diff_min,neg.data$diff_min)
boxplot(pos.data$diff_max,neg.data$diff_max)
boxplot(pos.data$perc_diff_min,neg.data$perc_diff_min)
boxplot(pos.data$perc_diff_max,neg.data$perc_diff_max)

# Correlation matrix
data[data$class=='false','clNum']=0
data[data$class=='true','clNum']=1
data2 <- subset( data, select = -class )
write.csv(cor(data2),file="correlationmatrix.csv") 

# Mann-Whitney U-Test
wilcox.test(pos.data$shared_length,neg.data$shared_length, alternative="greater")
wilcox.test(pos.data$tfidf_shared,neg.data$tfidf_shared, alternative="greater")
wilcox.test(pos.data$itfidf_shared,neg.data$itfidf_shared, alternative="greater")
wilcox.test(pos.data$perc_shared_length_min,neg.data$perc_shared_length_min, alternative="greater")
wilcox.test(pos.data$perc_shared_length_max,neg.data$perc_shared_length_max, alternative="greater")
wilcox.test(pos.data$diff_min,neg.data$diff_min)
wilcox.test(pos.data$diff_max,neg.data$diff_max)
wilcox.test(pos.data$perc_diff_min,neg.data$perc_diff_min)
wilcox.test(pos.data$perc_diff_max,neg.data$perc_diff_max)
wilcox.test(pos.data$context,neg.data$context, alternative="greater")
wilcox.test(pos.data$jaro,neg.data$jaro, alternative="greater")
wilcox.test(pos.data$jaccard,neg.data$jaccard, alternative="greater")
wilcox.test(pos.data$tversky,neg.data$tversky, alternative="greater")
