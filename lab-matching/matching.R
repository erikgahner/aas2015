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

# We will be using the lalonde data
data(lalonde)

# See the top rows
head(lalonde)

# View the data frame (opens in a new window)
View(lalonde)

# Call summary statistics for the data frame
summary(lalonde)

# Save the data frame in a new object (called lal)
lal <- lalonde

# Specify the treatment function, i.e. the variables accounting for selection into treatment
treat.f <- treat ~ re74 + re75 + age + factor(educ) + black + hisp + nodegr 

# Estimate a logistic regression model with glm() (generalized linear model)
# Save the estimates in an object called fit
fit <- glm(treat.f, family=binomial, data=lal)

# Show the estimates from the logit regression
summary(fit)

# Save a new column in the data frame lal with the propensity scores
lal$pscores <- predict(fit, type="response")

# Match observations using Nearest Neighborhood matching
matches <- matching(z=lal$treat, score=lal$pscores, replace=TRUE)

# Create a new data frame with the matched observations
matched <- lal[matches$matched,]

# Plot the propensity scores for the unmatched data frame
plot.unmatched <- ggplot(lal, aes(x=pscores, group=treat)) + 
  geom_density(data = lal[lal$treat == 1,], colour = "blue", fill = "blue", alpha = 0.1) + 
  geom_density(data = lal[lal$treat == 0,], colour = "red", fill = "red", alpha = 0.1) + 
  theme_bw() +
  ggtitle("Unmatched") +
  ylab("") +
  scale_x_continuous("Propensity score", limits=c(0,1))

# Plot the propensity scores for the matched data frame
# Remember: This plot lacks a variable indicating what the colours show
plot.matched <- ggplot(matched, aes(x=pscores, group=treat)) + 
  geom_density(data = matched[matched$treat == 1,], colour = "blue", fill = "blue", alpha = 0.1) + 
  geom_density(data = matched[matched$treat == 0,], colour = "red", fill = "red", alpha = 0.1) + 
  theme_bw() +
  ggtitle("Matched") +
  ylab("") +
  scale_x_continuous("Propensity score", limits=c(0,1))

# Show the two plots
grid.arrange(plot.unmatched, plot.matched, ncol=2)

# Save the plot in fig-overlap.pdf
pdf("fig-overlap.pdf", height=3, width=6)
grid.arrange(plot.unmatched, plot.matched, ncol=2)
dev.off()

# Check the balance between the unmatched and matched samples
## Unmatched 
xB.unmatched <- xBalance(treat.f, data=lal, report=c("all"))
xB.unmatched <- as.data.frame(xB.unmatched)
## Save z scores
z.unmatched <- xB.unmatched[,"results.z.unstrat"]

## Matched
xB.matched <- xBalance(treat.f, data=matched, report=c("all"))
xB.matched <- as.data.frame(xB.matched)
## Save z scores
z.matched <- xB.matched[,"results.z.unstrat"]

# Create a data frame with the z scores from both data frames
balance.df <- data.frame(covariate = row.names(xB.matched), unmatched=z.unmatched[row.names(xB.unmatched) %in% row.names(xB.matched)], matched=z.matched)
balance.df

# Plot the z scores
# Remember: This plot lacks better covariate names as well as a variable indicating what the colours show
fig.balance <- ggplot(balance.df, aes(x=covariate, y=unmatched)) + 
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

# Save the plot as a figure in fig-balance.pdf
pdf("fig-balance.pdf", height=3, width=6)
fig.balance
dev.off()

# Estimate the average effects of the treatment on real earning '78
# Note: We do not include any covarites here. Feel free to do that.
reg.unmatched <- lm(re78 ~ treat, data=lal)
reg.matched <- lm(re78 ~ treat, data=matched)
# Show the results
stargazer(reg.unmatched, reg.matched, type="text")

# Use the MatchIt package to match observations
# Nearest Neighborhood matching
m.nn <- matchit(treat.f, method = "nearest", replace=TRUE, data = lal)
m.nn.data <- match.data(m.nn)

# Show the number of matched units
m.nn

# Save the estimates from a OLS with the ATET
reg.nn <- lm(re78 ~ treat, data=m.nn.data, weights = weights)

# Compare the NN matching effects from the arm package
stargazer(reg.matched, reg.nn, type="text")

# Same procedure as with NN but with genetic matching
m.genetic <- matchit(treat.f, method = "genetic", data = lal)

m.genetic

m.genetic.data <- match.data(m.genetic)

reg.genetic <- lm(re78 ~ treat, data=m.genetic.data, weights = weights)

# Compare the results to the NN results
stargazer(reg.nn, reg.genetic, type="text")

# Same procedure for optimal matching
m.optimal <- matchit(treat.f, method = "optimal", data = lal)

m.optimal

m.optimal.data <- match.data(m.optimal)

reg.optimal <- lm(re78 ~ treat, data=m.optimal.data, weights = weights)

stargazer(reg.nn, reg.genetic, reg.optimal, type="text")

# And for coarsened exact matching
m.cem <- matchit(treat.f, method = "cem", data = lal)
m.cem

m.cem.data <- match.data(m.cem)
reg.cem <- lm(re78 ~ treat, data=m.cem.data, weights = weights)
stargazer(reg.nn, reg.genetic, reg.optimal, reg.cem, type="text")

# Save the results from the regressions in new data frames
df.reg.unmatched <- data.frame(name = "Unmatched", coef = coef(summary(reg.unmatched))["treat","Estimate"], se = coef(summary(reg.unmatched))["treat","Std. Error"])
df.reg.matched <- data.frame(name = "Matched (NN, arm)", coef = coef(summary(reg.matched))["treat","Estimate"], se = coef(summary(reg.matched))["treat","Std. Error"])
df.reg.nn <- data.frame(name = "Matched (NN)", coef = coef(summary(reg.nn))["treat","Estimate"], se = coef(summary(reg.nn))["treat","Std. Error"])
df.reg.genetic <- data.frame(name = "Matched (Gentic)", coef = coef(summary(reg.genetic))["treat","Estimate"], se = coef(summary(reg.genetic))["treat","Std. Error"])
df.reg.optimal <- data.frame(name = "Matched (Optimal)", coef = coef(summary(reg.optimal))["treat","Estimate"], se = coef(summary(reg.optimal))["treat","Std. Error"])
df.reg.cem <- data.frame(name = "Matched (CEM)", coef = coef(summary(reg.cem))["treat","Estimate"], se = coef(summary(reg.cem))["treat","Std. Error"])

# Create one data frame with all the results
df.reg <- data.frame(rbind(df.reg.unmatched, df.reg.matched, df.reg.nn, df.reg.genetic, df.reg.optimal, df.reg.cem))

# Plot the effects in one plot
fig.effects <- ggplot(df.reg, aes(colour = name)) + 
  geom_hline(yintercept = 0, colour = gray(1/2), lty = 2) +
  geom_linerange(size=1.5, aes(x = name, ymin = coef - se*1.64, ymax = coef + se*1.64)) +
  geom_pointrange(size=1, aes(x = name, y = coef, ymin = coef - se*1.96, ymax = coef + se*1.96)) +
  ylab("Effect") +
  xlab("") +
  coord_flip() +
  theme_bw() +
  theme(legend.position="none", panel.grid.major = element_blank())

# Save the plot in figure fig-effects.pdf
pdf("fig-effects.pdf", height=3, width=6)
fig.effects
dev.off()

# Write the data frame to a .csv file called lalonde.csv
write.csv(lal, "lalonde.csv")