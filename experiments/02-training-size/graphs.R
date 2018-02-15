library(ggplot2)
library(plyr)

loadData <- function(f='experiments/02-training-size/results-10-8900/all-results.tsv') {
  read.table(f,header=TRUE)
}

boxplots <- function(d,nb=0,ymin=0,withnotch=FALSE,fontsize=26) {
  if (nb>0) {
    modu<-round(max(d$no)/nb,0)
    print(modu)
    d<- d[d$no %% modu==0,]
  }
  g<-ggplot(d,aes(as.factor(nbSentences),perf))+geom_boxplot(notch=withnotch)+ scale_y_continuous(labels = scales::percent)+xlab('Number of sentences') + theme_grey(base_size = fontsize)+theme(axis.title.y=element_blank())
  if (ymin!=0) {
    g<-g+coord_cartesian(ylim=c(ymin,1)) 
  }
  g
}


meanByNbSent <- function(d) {
  ddply(d,'nbSentences',function(df) {
    data.frame(meanperf=mean(df$perf),medianperf=median(df$perf),sd(df$perf))
  })
}