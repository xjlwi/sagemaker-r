
# Model constants.
control <- trainControl(method="cv", number=10)
metric <- "Accuracy"

# Load data from Github Example. Requires internet.
data <- read.csv("https://raw.githubusercontent.com/trevorwitter/Iris-classification-R/master/iris.csv")
#load data from CSV file
# data <- read.csv("iris.csv", header=FALSE) 

# et data frame column names 
colnames(data) <- c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species")

# Split data into train/test sets using createDataPartition()
data_split <- createDataPartition(data$Species, p = 0.8, list = FALSE)

test <- data[-data_split,] # Save 20% of data for test validation here
dataset <- data[data_split,] # 80% of data 