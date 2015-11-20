# R script to lab session 7, "Matching".
# Also available at https://github.com/erikgahner/aas2015

# Load packages -- you can install a package by using install.packages("PACKAGE")
library("MASS")
library("survival")
library("Matrix")
library("lme4")
library("tcltk")
library("lattice")
library("ggplot2")    
library("stargazer")  
library("gridExtra")
library("MatchIt")
library("optmatch")
library("survival")
library("cem")
library("RItools")
library("arm")        

# Set our random number to make sure we get the same output
set.seed(30134002)

# We will be using the lalonde data (LaLonde 1986)
data(lalonde)

# See the 
head(lalonde)

View(lalonde)

summary(lalonde)

lal <- lalonde

treat.f <- treat ~ re74 + re75 + age + factor(educ) + black + hisp + nodegr 

fit <- glm(treat.f, family=binomial, data=lal)

summary(fit)

lal$pscores <- predict(fit, type="response")

matches <- matching(z=lal$treat, score=lal$pscores, replace=TRUE)

matched <- lal[matches$matched,]

plot.unmatched <- ggplot(lal, aes(x=pscores, group=treat)) + 
  geom_density(data = lal[lal$treat == 1,], colour = "blue", fill = "blue", alpha = 0.1) + 
  geom_density(data = lal[lal$treat == 0,], colour = "red", fill = "red", alpha = 0.1) + 
  theme_bw() +
  ggtitle("Unmatched") +
  ylab("") +
  scale_x_continuous("Propensity score", limits=c(0,1))

plot.matched <- ggplot(matched, aes(x=pscores, group=treat)) + 
  geom_density(data = matched[matched$treat == 1,], colour = "blue", fill = "blue", alpha = 0.1) + 
  geom_density(data = matched[matched$treat == 0,], colour = "red", fill = "red", alpha = 0.1) + 
  theme_bw() +
  ggtitle("Matched") +
  ylab("") +
  scale_x_continuous("Propensity score", limits=c(0,1))

grid.arrange(plot.unmatched, plot.matched, ncol=2)

pdf("fig-overlap.pdf", height=3, width=6)
grid.arrange(plot.unmatched, plot.matched, ncol=2)
dev.off()

xB.unmatched <- xBalance(treat.f, data=lal, report=c("all"))
xB.unmatched <- as.data.frame(xB.unmatched)
z.unmatched <- xB.unmatched[,"results.z.unstrat"]

xB.matched <- xBalance(treat.f, data=matched, report=c("all"))
xB.matched <- as.data.frame(xB.matched)
z.matched <- xB.matched[,"results.z.unstrat"]

balance.df <- data.frame(covariate = row.names(xB.matched), unmatched=z.unmatched[row.names(xB.unmatched) %in% row.names(xB.matched)], matched=z.matched)
balance.df

ggplot(balance.df, aes(x=covariate, y=unmatched)) + 
  geom_point(aes(y=unmatched, size=2), colour="red", alpha = 0.6) + 
  geom_point(aes(y=matched, size=2), colour="blue", alpha = 0.6) + 
  coord_flip() +
  geom_hline(yintercept=0, linetype="dashed", colour="gray50") +
  geom_hline(yintercept=-1.96, linetype="dotted", colour="gray50") +
  geom_hline(yintercept=1.96, linetype="dotted", colour="gray50") +
  xlab("") +
  ylab("Z score") +
  theme_bw() +
  theme(legend.position="none", panel.grid.major = element_blank())

reg.unmatched <- lm(re78 ~ treat, data=lal)
reg.matched <- lm(re78 ~ treat, data=matched)
stargazer(reg.unmatched, reg.matched, type="text")

m.nn <- matchit(treat.f, method = "nearest", replace=TRUE, data = lal)
m.nn.data <- match.data(m.nn)

m.nn

reg.nn <- lm(re78 ~ treat, data=m.nn.data, weights = weights)

stargazer(reg.matched, reg.nn, type="text")

m.genetic <- matchit(treat.f, method = "genetic", data = lal)

m.genetic

m.genetic.data <- match.data(m.genetic)

reg.genetic <- lm(re78 ~ treat, data=m.genetic.data, weights = weights)

stargazer(reg.nn, reg.genetic, type="text")

m.optimal <- matchit(treat.f, method = "optimal", data = lal)

m.optimal

m.optimal.data <- match.data(m.optimal)

reg.optimal <- lm(re78 ~ treat, data=m.optimal.data, weights = weights)

stargazer(reg.nn, reg.genetic, reg.optimal, type="text")

m.cem <- matchit(treat.f, method = "cem", data = lal)
m.cem

m.cem.data <- match.data(m.cem)
reg.cem <- lm(re78 ~ treat, data=m.cem.data, weights = weights)
stargazer(reg.nn, reg.genetic, reg.optimal, reg.cem, type="text")

df.reg.unmatched <- data.frame(name = "Unmatched", coef = coef(summary(reg.unmatched))["treat","Estimate"], se = coef(summary(reg.unmatched))["treat","Std. Error"])
df.reg.matched <- data.frame(name = "Matched (NN, arm)", coef = coef(summary(reg.matched))["treat","Estimate"], se = coef(summary(reg.matched))["treat","Std. Error"])
df.reg.nn <- data.frame(name = "Matched (NN)", coef = coef(summary(reg.nn))["treat","Estimate"], se = coef(summary(reg.nn))["treat","Std. Error"])
df.reg.genetic <- data.frame(name = "Matched (Gentic)", coef = coef(summary(reg.genetic))["treat","Estimate"], se = coef(summary(reg.genetic))["treat","Std. Error"])
df.reg.optimal <- data.frame(name = "Matched (Optimal)", coef = coef(summary(reg.optimal))["treat","Estimate"], se = coef(summary(reg.optimal))["treat","Std. Error"])
df.reg.cem <- data.frame(name = "Matched (CEM)", coef = coef(summary(reg.cem))["treat","Estimate"], se = coef(summary(reg.cem))["treat","Std. Error"])
df.reg <- data.frame(rbind(df.reg.unmatched, df.reg.matched, df.reg.nn, df.reg.genetic, df.reg.optimal, df.reg.cem))

effects <- ggplot(df.reg, aes(colour = name)) + 
  geom_hline(yintercept = 0, colour = gray(1/2), lty = 2) +
  geom_linerange(size=1.5, aes(x = name, ymin = coef - se*1.64, ymax = coef + se*1.64)) +
  geom_pointrange(size=1, aes(x = name, y = coef, ymin = coef - se*1.96, ymax = coef + se*1.96)) +
  ylab("Effect") +
  xlab("") +
  coord_flip() +
  theme_bw() +
  theme(legend.position="none", panel.grid.major = element_blank())

pdf("fig-effects.pdf", height=3, width=6)
effects
dev.off()

write.csv(lal, "lalonde.csv")