# Gifthealth Engineering Project

For this step in the interview process we're going to ask you to write some code for a small project. You're welcome to use whatever language you want and we encourage you to use the language/tooling that you're most comfortable with. We want to see your technical ability in an environment where you're not limited by unfamiliar language/tooling.

We also ask that you include a README along with your submission explaining the design you chose, any assumptions you made, and notable architecture tradeoffs you landed on. See the "Evaluation Criteria" section for more details.

If you have any questions about the project please reach out to your main hiring contact or mike@gifthealth.com. If the project description doesn't cover something you can make whatever assumption you would like. We just ask that you document it in the README. Your solution will not be judged on any assumptions you make that was not covered in the project description.

## Submitting the project

Please create a zip file with the contents of your project and submit it to your main point of contact during the interview process via email.

## Project

Your program should accept an input file via a filename argument (ex. command filename.txt) or via stdin (ex. cat filename.txt | command). The input file is space-delimited and contains a series of prescription events for a pharmacy system. Events are recorded in the file in the order they happen. Note: none of the data will contain spaces.

The format of each line is: `PatientName DrugName EventName`

There are 3 event types with the following behavior:

- **created** - Indicates the prescription is created in the system. A prescription must be created before it can be filled or returned. Any filled or returned events prior to a created event must be discarded. Multiple created events will not show up for the same prescription.

- **filled** - Indicates the prescription has been filled. A prescription can be filled multiple times.

- **returned** - Indicates that a previously filled prescription has been returned. This cancels out a prior filled event. A return event will always have a prior filled event.

Your goal is to produce a report to stdout which prints a line for every patient, the total number of fills for that patient, and the total income for the patient (see the "How Income Works" section).

The output format should look like: `PatientName TotalFills Income`. See the expected output below.

## How Income Works

- Every prescription filled results in $5 of income.
- Each time a prescription is returned it results in a $1 loss. Even if it's filled again later.

## Sample input

```
Nick A created
Mark B created
Mark B filled
Mark C filled
Mark B returned
John E created
Mark B filled
Mark B filled
Paul D filled
John E filled
John E returned
```

## Expected output

```
Mark: 2 fills $9 income
John: 0 fills -$1 income
Nick: 0 fills $0 income
```

## Evaluation Criteria

The intent of this project is for us to understand your technical skills without spending a ton of time on a large project.

While this is a small project the expectation is production quality code. This includes testing, design, and code hygiene. You don't need to go overboard with design (fun example: Enterprise FizzBuzz), but we expect something more sophisticated than a single function.

We also want to understand the thought process behind your architecture decisions for the project. Use the README to expand on your thought process, architecture decisions, and tradeoffs you made during the project. What data structures did you use? How did you choose to organize your code? Any design tradeoffs that you want to highlight? Take some time to walk us through your thought process on these questions and expand on them as needed. Keep in mind, there is no "right" answer here. We're interested in your thought process and the "why". Detailing your thought process is just as important as the code itself.

We'll specifically be looking at the following aspects:

- Architecture and design
- Code readability and understandability
- Testing strategy
- Design explanation in README

