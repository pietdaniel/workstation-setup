#!/usr/bin/env zsh
MESSAGE=$1

if [ -z "$MESSAGE" ]; then
    APHORISMS=(
        "The only way to do great work is to love what you do. — Steve Jobs"
        "Simplicity is the ultimate sophistication. — Leonardo da Vinci"
        "Talk is cheap. Show me the code. — Linus Torvalds"
        "First, solve the problem. Then, write the code. — John Johnson"
        "The best time to plant a tree was 20 years ago. The second best time is now. — Chinese Proverb"
        "It does not matter how slowly you go as long as you do not stop. — Confucius"
        "The only true wisdom is in knowing you know nothing. — Socrates"
        "In the middle of difficulty lies opportunity. — Albert Einstein"
        "Well done is better than well said. — Benjamin Franklin"
        "Knowing is not enough; we must apply. — Johann Wolfgang von Goethe"
        "Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away. — Antoine de Saint-Exupéry"
        "The impediment to action advances action. What stands in the way becomes the way. — Marcus Aurelius"
        "Make it work, make it right, make it fast. — Kent Beck"
        "Premature optimization is the root of all evil. — Donald Knuth"
        "Any fool can write code that a computer can understand. Good programmers write code that humans can understand. — Martin Fowler"
        "The best error message is the one that never shows up. — Thomas Fuchs"
        "Code is like humor. When you have to explain it, it's bad. — Cory House"
        "Experience is simply the name we give our mistakes. — Oscar Wilde"
        "A ship in harbor is safe, but that is not what ships are built for. — John A. Shedd"
        "The mind is everything. What you think you become. — Buddha"
        "Be yourself; everyone else is already taken. — Oscar Wilde"
        "Two things are infinite: the universe and human stupidity; and I'm not sure about the universe. — Albert Einstein"
        "Be the change that you wish to see in the world. — Mahatma Gandhi"
        "Without deviation from the norm, progress is not possible. — Frank Zappa"
        "Stay hungry, stay foolish. — Steve Jobs"
        "The unexamined life is not worth living. — Socrates"
        "Imagination is more important than knowledge. — Albert Einstein"
        "Genius is one percent inspiration and ninety-nine percent perspiration. — Thomas Edison"
        "I think, therefore I am. — René Descartes"
        "That which does not kill us makes us stronger. — Friedrich Nietzsche"
        "The only thing we have to fear is fear itself. — Franklin D. Roosevelt"
        "To be, or not to be, that is the question. — William Shakespeare"
        "I have not failed. I've just found 10,000 ways that won't work. — Thomas Edison"
        "The greatest glory in living lies not in never falling, but in rising every time we fall. — Nelson Mandela"
        "Life is what happens when you're busy making other plans. — John Lennon"
        "The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt"
        "It is during our darkest moments that we must focus to see the light. — Aristotle"
        "Do what you can, with what you have, where you are. — Theodore Roosevelt"
        "If you want to go fast, go alone. If you want to go far, go together. — African Proverb"
        "The measure of intelligence is the ability of change. — Albert Einstein"
        "Strive not to be a success, but rather to be of value. — Albert Einstein"
        "You must be the change you wish to see in the world. — Mahatma Gandhi"
        "An investment in knowledge pays the best interest. — Benjamin Franklin"
        "The secret of getting ahead is getting started. — Mark Twain"
        "Quality is not an act, it is a habit. — Aristotle"
        "We are what we repeatedly do. Excellence, then, is not an act, but a habit. — Will Durant"
        "The journey of a thousand miles begins with one step. — Lao Tzu"
        "Everything has beauty, but not everyone sees it. — Confucius"
        "Life is really simple, but we insist on making it complicated. — Confucius"
        "The purpose of our lives is to be happy. — Dalai Lama"
        "You miss 100% of the shots you don't take. — Wayne Gretzky"
        "Whether you think you can or you think you can't, you're right. — Henry Ford"
        "The only impossible journey is the one you never begin. — Tony Robbins"
        "Programs must be written for people to read, and only incidentally for machines to execute. — Harold Abelson"
        "Measuring programming progress by lines of code is like measuring aircraft building progress by weight. — Bill Gates"
        "The most disastrous thing that you can ever learn is your first programming language. — Alan Kay"
        "The function of good software is to make the complex appear to be simple. — Grady Booch"
        "Before software can be reusable it first has to be usable. — Ralph Johnson"
        "One of my most productive days was throwing away 1,000 lines of code. — Ken Thompson"
        "Deleted code is debugged code. — Jeff Sickel"
        "The best way to predict the future is to invent it. — Alan Kay"
        "Computers are useless. They can only give you answers. — Pablo Picasso"
        "The advance of technology is based on making it fit in so that you don't really even notice it, so it's part of everyday life. — Bill Gates"
        "Innovation distinguishes between a leader and a follower. — Steve Jobs"
        "The science of today is the technology of tomorrow. — Edward Teller"
        "It has become appallingly obvious that our technology has exceeded our humanity. — Albert Einstein"
        "The real problem is not whether machines think but whether men do. — B.F. Skinner"
        "Luck is what happens when preparation meets opportunity. — Seneca"
        "No man is free who is not master of himself. — Epictetus"
        "We suffer more often in imagination than in reality. — Seneca"
        "Waste no more time arguing about what a good man should be. Be one. — Marcus Aurelius"
        "He who has a why to live can bear almost any how. — Friedrich Nietzsche"
        "Man is condemned to be free. — Jean-Paul Sartre"
        "One cannot step twice in the same river. — Heraclitus"
        "Happiness is not something ready made. It comes from your own actions. — Dalai Lama"
        "Virtue is not given by money, but from virtue comes money. — Socrates"
        "To live is the rarest thing in the world. Most people exist, that is all. — Oscar Wilde"
        "Turn your wounds into wisdom. — Oprah Winfrey"
        "The best revenge is massive success. — Frank Sinatra"
        "If you cannot do great things, do small things in a great way. — Napoleon Hill"
        "What we achieve inwardly will change outer reality. — Plutarch"
        "Brevity is the soul of wit. — William Shakespeare"
        "Give me a lever long enough and a fulcrum on which to place it, and I shall move the world. — Archimedes"
        "There is nothing permanent except change. — Heraclitus"
        "The greatest wealth is to live content with little. — Plato"
        "Patience is bitter, but its fruit is sweet. — Jean-Jacques Rousseau"
        "Science is organized knowledge. Wisdom is organized life. — Immanuel Kant"
        "Liberty means responsibility. That is why most men dread it. — George Bernard Shaw"
        "Not all those who wander are lost. — J.R.R. Tolkien"
        "The only thing I know is that I know nothing. — Socrates"
        "Doubt is the origin of wisdom. — René Descartes"
        "You can never cross the ocean until you have the courage to lose sight of the shore. — Christopher Columbus"
        "Act as if what you do makes a difference. It does. — William James"
        "Success is not final, failure is not fatal: it is the courage to continue that counts. — Winston Churchill"
        "Wisdom begins in wonder. — Socrates"
        "The energy of the mind is the essence of life. — Aristotle"
        "Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment. — Buddha"
        "A fool thinks himself to be wise, but a wise man knows himself to be a fool. — William Shakespeare"
        "The true sign of intelligence is not knowledge but imagination. — Albert Einstein"
        "Logic will get you from A to B. Imagination will take you everywhere. — Albert Einstein"
        "To know oneself is the beginning of wisdom. — Aristotle"
        "He who opens a school door, closes a prison. — Victor Hugo"
    )
    RANDOM_INDEX=$((RANDOM % ${#APHORISMS[@]}))
    MESSAGE="${APHORISMS[$((RANDOM_INDEX + 1))]}"
    echo "No message provided. Using: $MESSAGE"
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "Cannot push and open a PR from $BRANCH. Please switch to a feature branch."
    exit 1
fi

# check if opencode exists
if ! command -v opencode &> /dev/null
then
    echo "opencode could not be found, please install it first."
    exit 1
fi

git add -A
git commit -m "$MESSAGE"
git push -u origin "$BRANCH"

PR_URL=$(gh pr create --fill 2>&1)
if [ $? -ne 0 ]; then
    echo "Failed to create PR: $PR_URL"
    exit 1
fi

echo "PR created: $PR_URL"

opencode run "Please update the Title and Description of this PR: $PR_URL"
