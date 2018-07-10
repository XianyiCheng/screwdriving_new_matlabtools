#### how to load data from files: 

**Syntax:**

rundata = RunData(directory, bagname);

**Examples:**

rundata = RunData('./test/run_1','screwdriver_0_5_1528414903');

#### how to label data 

**Syntax:**

load dataset: dataset = Dataset(directory,context_path);
label data: dataset.labeldata(index);

**Examples:**

dataset = Dataset('./test/run_1', 'labels.json');
dataset.labeldata(5)
