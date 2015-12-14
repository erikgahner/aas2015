# R script to lab session 6, "Introduction to R".
# Also available at https://github.com/erikgahner/aas2015

# As you can se, "#" in R is equivalent to "*" / "//" in Stata

# We can calculate stuff 
## Highlight the line and press CTRL+R (Windows) or CMD+R (Mac)
2+2             # Like "display 2+2" in Stata
50*149
3**2            # 3^2
2**3            # 2^3
sqrt(81)

# R work with objects. We can save everything in objects.
## The arrow is identical to using "=", but please stick to "<-"
x <- 2  ## You can also type 2 -> x

x

# Logical operations (you get TRUE or FALSE)
x == 2        # Try to change the value of x above (e.g. to 3).
x == 3        # "==" means "equal to"
x != 2        # "!=" means "not equal to"
x < 1
x > 1
x <= 2
x >= 2.01

# What class is x? (There are different object classes in R)
class(x)      # x is a number, thus a numeric class

# By the way, R is case sensitive
class(X)  # x != X
Class(x)  # Class() != class()

# We can use our object for whatever we feel for
x       # show the value in the object
x + 2   # the value of x plus 2

x*x*x   # x times x times x

y <- x + 2    # We can create a new object with our object
y       # show the value of y

# List numbers 1 to 10
1:10    # the same as c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10) ... we get to c() in a moment

# What do you think this will do? 
## a) 1  2  3  4  5  6  7  8  9 10 2 
## b) 3  4  5  6  7  8  9 10 11 12
1:10 + 2  # Why? 

# We can also combine numbers into vectors and lists
c(2, 2, 2)

# Let us save a numeric vector. A vector is simply a collection of multiple values with the same type of data
x <- c(14, 6, 23, 2)
x
x * 2

# Is it a numeric vector?
is.numeric(x)
is.character(x)   # We will get to characters in a moment

# What is the second number?
x[3]

# Can we remove the second number? Yes.
x[-2]

# We can get a lot of information
length(x)     # the number of numbers in our vector
min(x)        # the minimum value
max(x)        # the maximum value
median(x)     # the median
sum(x)        # the sum
mean(x)       # the mean
var(x)        # the variance

sd(x)         # the standard deviation

sqrt(var(x)) == sd(x) ## True dat.

x <- c(x, 5)
x

mean(x)

# Missing values: In R "NA" is equivalent to "." in Stata

x <- c(x, NA)

mean(x)     # NA!?

mean(x, na.rm=TRUE)

mean(x, na.rm=T)    # T is an abbreviation for TRUE

?mean ### two marks question for online search: ??mean

# What about text?
z <- c("Venstre", "Socialdemokraterne") # note the quotation marks

z

class(z)

# We can add some more parties
party <- c(z, "Enhedslisten", "SF", "Radikale", "Konservative", 
           "Dansk Folkeparti", "Liberal Alliance", "Alternativet")

rw <- c(1, 0, 0, 0, 0, 1, 1, 1, 0)  # add info on whether the party is a right-wing party or not
                                    # note the order, beginning with Venstre, ending with Alternativet

party

vote <- c(19.5, 26.3, 7.8, 4.2, 4.6, 3.4, 21.1, 7.5, 4.8)

seat <- c(34, 47, 14, 7, 8, 6, 37, 13, 9)

# Create a data frame (similar to a data set in Stata)
pol <- data.frame(party, vote, seat, rw)

# Show the data frame
pol 

# Show the data frame in a new window (good when working with large data frames)
# Similar to "browse" in Stata
View(pol)

# Show the first six observations
head(pol)

# Show the first three observations
head(pol, 3)

# Show the last six observations
tail(pol)

# The class should be a data frame
class(pol)

# Show votes in data frame. Note the dollar sign (component selector).
pol$vote

pol[1, 1] # first row, first colun
pol[1,] # first row
pol[,1] # first column

max(pol$vote)

pol$party[1]

pol$party[pol$vote == max(pol$vote)]

pol$party[pol$vote == min(pol$vote)]

# What is the correlation between votes and seats? 
cor(pol$vote, pol$seat) # Wow.
with(pol, cor(vote, seat))

# We can even plot stuff
plot(pol$vote, pol$seat)

# Let's make a better plot

# R has a lot of packages. We will intall the ggplot2 package
install.packages("ggplot2")

# Load the ggplot2 package
library("ggplot2")

# Your first plot. Notice the "+".
ggplot(pol, aes(x=vote, y=seat)) +  # ggplot(DATA.FRAME, aes( )) +
  geom_point(size=4)

# Use the minimal theme
ggplot(pol, aes(x=vote, y=seat)) +
  geom_point(size=4) +
  theme_minimal() 

# Create a variable with colours 
pol$rw.c <- ifelse(pol$rw==1, "blue", "red")


# Add colours
ggplot(pol, aes(x=vote, y=seat)) +
  geom_point(col=pol$rw.c, alpha=0.6, size=4) +
  theme_minimal() 

# Change x- and y-axis titles
ggplot(pol, aes(x=vote, y=seat)) +
  geom_point(col=pol$rw.c, alpha=0.6, size=4) +
  theme_minimal() +
  ylab("Seats") +
  xlab("Votes (%)")

# Add a label for the Social Democrats
ggplot(pol, aes(x=vote, y=seat)) +
  geom_point(col=pol$rw.c, alpha=0.6, size=4) +
  theme_minimal() +
  ylab("Seats") +
  xlab("Votes (%)") +
  geom_text(aes(label=ifelse(party == "Socialdemokraterne", "Social Democrats",''), hjust=1.1, vjust=0.5))

# Let's "open" some data, i.e. load data into a data frame
# It is important that you have the correct working directory
getwd()     # You can use setwd() to change it
# The data is simulated data from LaCour & Green (2014)
lacour <- read.csv("lacoursciencedata.csv")

# We can view the data
View(lacour)

# We subset the data to the observations used in Simulation 1
lacour <- subset(lacour, STUDY == "Study 1")

# Before we go any further: Remember, if this was in Stata, our old data set would be gone.
# However, in R, we can have data frames in different objects at the same time
pol   # See, still there.

# Our data should be...
class(lacour)

# We can get descriptive statistics on all variables with summary()
summary(lacour)

# Does feelings toward gays affect support for same sex marriage?
reg.ssm <- lm(SSM_Level ~ Therm_Level, data=lacour)  # In Stata: reg SSM_level Therm_Level
summary(reg.ssm)

library(stargazer)
?stargazer
stargazer(reg.ssm, type="text")

# Let's see if people interviewed in Wave 2 are more likely to have positive feelings toward gays
reg.therm <- lm(Therm_Change ~ Treatment_Assignment, data=lacour[lacour$wave==2 & lacour$Contact!="Secondary",])
summary(reg.therm)
stargazer(reg.therm, type="text")

# Last, we can see all we have
ls()

# Do you want to remove something?
rm(x)

ls()

# Do you want to remove EVERYTHING!?
rm(list = ls())

ls()