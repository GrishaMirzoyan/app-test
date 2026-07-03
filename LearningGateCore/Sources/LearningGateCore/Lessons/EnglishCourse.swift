import Foundation

// The built-in beginner English course (A0/A1).
//
// Content is deliberately language-neutral: vocabulary is taught with emoji
// cues and grammar with fill-the-blank / build-the-sentence exercises, so the
// same course works for speakers of any language without translation packs.
// IDs are stable strings so learner progress survives content additions —
// append new lessons/exercises, never reuse or renumber existing IDs.

extension Course {
    public static let beginnerEnglish = Course(
        id: CourseID("en.beginner"),
        title: "English Basics",
        units: [firstWords, smallSentences, everyDay]
    )
}

// MARK: - Authoring helpers

private func choice(_ id: String, _ prompt: String, _ choices: [String], _ answer: String) -> Exercise {
    guard let index = choices.firstIndex(of: answer) else {
        preconditionFailure("Course content bug: answer \"\(answer)\" not in choices for \(id)")
    }
    return Exercise(id: ExerciseID(id), kind: .choice(prompt: prompt, choices: choices, answerIndex: index))
}

/// Word bank = the answer's words plus distractors; the UI shuffles display order.
private func build(_ id: String, _ prompt: String, _ answer: String, extra: [String] = []) -> Exercise {
    let words = answer.split(separator: " ").map(String.init) + extra
    return Exercise(id: ExerciseID(id), kind: .wordOrder(prompt: prompt, words: words, answer: answer))
}

private func type(_ id: String, _ prompt: String, _ answer: String, accepted: [String] = []) -> Exercise {
    Exercise(id: ExerciseID(id), kind: .typeAnswer(prompt: prompt, answer: answer, accepted: accepted))
}

// MARK: - Unit 1 · First Words

private let firstWords = CourseUnit(
    id: CourseUnitID("en.u1"),
    title: "First Words",
    lessons: [
        Lesson(id: LessonID("en.u1.l1"), title: "Greetings", icon: "👋", exercises: [
            choice("en.u1.l1.e1", "👋 Hi!", ["Hello", "Goodbye", "No", "Cat"], "Hello"),
            choice("en.u1.l1.e2", "🙏 Someone helps you. You say…", ["Thank you", "Hello", "Goodbye", "Yes"], "Thank you"),
            choice("en.u1.l1.e3", "✅", ["Yes", "No", "Please", "Stop"], "Yes"),
            choice("en.u1.l1.e4", "❌", ["No", "Yes", "Thanks", "Go"], "No"),
            build("en.u1.l1.e5", "🌅 Greet someone in the morning", "Good morning", extra: ["night"]),
            build("en.u1.l1.e6", "🌙 Say goodbye at night", "Good night", extra: ["morning"]),
            type("en.u1.l1.e7", "👋 Type the greeting", "hello", accepted: ["hi"])
        ]),
        Lesson(id: LessonID("en.u1.l2"), title: "People", icon: "🧑‍🤝‍🧑", exercises: [
            choice("en.u1.l2.e1", "👨", ["man", "woman", "boy", "girl"], "man"),
            choice("en.u1.l2.e2", "👩", ["woman", "man", "girl", "boy"], "woman"),
            choice("en.u1.l2.e3", "👦", ["boy", "girl", "man", "woman"], "boy"),
            choice("en.u1.l2.e4", "👧", ["girl", "boy", "woman", "man"], "girl"),
            choice("en.u1.l2.e5", "👶", ["baby", "friend", "man", "dog"], "baby"),
            build("en.u1.l2.e6", "👩 Say what she is", "She is a woman", extra: ["he"]),
            type("en.u1.l2.e7", "👨 Type the word", "man")
        ]),
        Lesson(id: LessonID("en.u1.l3"), title: "Food & Drink", icon: "🍎", exercises: [
            choice("en.u1.l3.e1", "🍎", ["apple", "bread", "milk", "water"], "apple"),
            choice("en.u1.l3.e2", "🍞", ["bread", "apple", "tea", "rice"], "bread"),
            choice("en.u1.l3.e3", "💧", ["water", "milk", "coffee", "juice"], "water"),
            choice("en.u1.l3.e4", "🥛", ["milk", "water", "tea", "bread"], "milk"),
            choice("en.u1.l3.e5", "☕", ["coffee", "milk", "water", "apple"], "coffee"),
            build("en.u1.l3.e6", "🍎💚 Say what you like", "I like apples", extra: ["bread"]),
            type("en.u1.l3.e7", "💧 Type the word", "water")
        ]),
        Lesson(id: LessonID("en.u1.l4"), title: "Animals", icon: "🐶", exercises: [
            choice("en.u1.l4.e1", "🐶", ["dog", "cat", "bird", "fish"], "dog"),
            choice("en.u1.l4.e2", "🐱", ["cat", "dog", "horse", "bird"], "cat"),
            choice("en.u1.l4.e3", "🐦", ["bird", "fish", "cat", "cow"], "bird"),
            choice("en.u1.l4.e4", "🐟", ["fish", "bird", "dog", "horse"], "fish"),
            choice("en.u1.l4.e5", "🐴", ["horse", "cow", "cat", "dog"], "horse"),
            build("en.u1.l4.e6", "🐱💚 Say what you like", "I like cats", extra: ["dogs"]),
            type("en.u1.l4.e7", "🐶 Type the word", "dog")
        ])
    ]
)

// MARK: - Unit 2 · Small Sentences

private let smallSentences = CourseUnit(
    id: CourseUnitID("en.u2"),
    title: "Small Sentences",
    lessons: [
        Lesson(id: LessonID("en.u2.l1"), title: "I am, you are", icon: "🙋", exercises: [
            choice("en.u2.l1.e1", "I ___ a student.", ["am", "is", "are"], "am"),
            choice("en.u2.l1.e2", "You ___ my friend.", ["are", "am", "is"], "are"),
            choice("en.u2.l1.e3", "She ___ a woman.", ["is", "am", "are"], "is"),
            choice("en.u2.l1.e4", "We ___ happy. 😊", ["are", "is", "am"], "are"),
            build("en.u2.l1.e5", "🙋 Say who you are", "I am a student", extra: ["is"]),
            build("en.u2.l1.e6", "😊 Say she is happy", "She is happy", extra: ["am"]),
            type("en.u2.l1.e7", "He ___ my friend. Type the missing word", "is")
        ]),
        Lesson(id: LessonID("en.u2.l2"), title: "A or an", icon: "🔤", exercises: [
            choice("en.u2.l2.e1", "This is ___ apple. 🍎", ["an", "a", "the"], "an"),
            choice("en.u2.l2.e2", "This is ___ dog. 🐶", ["a", "an", "the"], "a"),
            choice("en.u2.l2.e3", "She has ___ orange. 🍊", ["an", "a", "the"], "an"),
            choice("en.u2.l2.e4", "I have ___ cat. 🐱", ["a", "an", "the"], "a"),
            build("en.u2.l2.e5", "🍎 Say what this is", "This is an apple", extra: ["a"]),
            build("en.u2.l2.e6", "🐶 Say what that is", "That is a dog", extra: ["an"])
        ]),
        Lesson(id: LessonID("en.u2.l3"), title: "I like, I want", icon: "💚", exercises: [
            choice("en.u2.l3.e1", "I ___ coffee. ☕💚", ["like", "am", "is"], "like"),
            choice("en.u2.l3.e2", "I ___ water, please. 💧🙏", ["want", "am", "are"], "want"),
            choice("en.u2.l3.e3", "She ___ tea. 🍵💚", ["likes", "like", "want"], "likes"),
            choice("en.u2.l3.e4", "We ___ bread. 🍞💚", ["like", "likes", "is"], "like"),
            build("en.u2.l3.e5", "🥛🙏 Ask for milk", "I want milk please", extra: ["like"]),
            build("en.u2.l3.e6", "☕💚 Say you like coffee", "I like coffee", extra: ["want"]),
            type("en.u2.l3.e7", "🍎💚 I ___ apples. Type the missing word", "like")
        ]),
        Lesson(id: LessonID("en.u2.l4"), title: "Questions", icon: "❓", exercises: [
            choice("en.u2.l4.e1", "___ is your name?", ["What", "Where", "Who"], "What"),
            choice("en.u2.l4.e2", "___ are you from?", ["Where", "What", "Who"], "Where"),
            choice("en.u2.l4.e3", "___ is that man? 👨", ["Who", "What", "Where"], "Who"),
            choice("en.u2.l4.e4", "___ old are you?", ["How", "What", "Who"], "How"),
            build("en.u2.l4.e5", "❓👤 Ask someone's name", "What is your name", extra: ["where"]),
            build("en.u2.l4.e6", "❓🌍 Ask where someone is from", "Where are you from", extra: ["what"])
        ])
    ]
)

// MARK: - Unit 3 · Every Day

private let everyDay = CourseUnit(
    id: CourseUnitID("en.u3"),
    title: "Every Day",
    lessons: [
        Lesson(id: LessonID("en.u3.l1"), title: "Days & Numbers", icon: "📅", exercises: [
            choice("en.u3.l1.e1", "Today is Monday. Tomorrow is ___.", ["Tuesday", "Sunday", "Friday"], "Tuesday"),
            choice("en.u3.l1.e2", "🌅 Good ___!", ["morning", "night", "apple"], "morning"),
            choice("en.u3.l1.e3", "🌙 Good ___!", ["night", "morning", "water"], "night"),
            choice("en.u3.l1.e4", "One, two, ___ 3️⃣", ["three", "four", "five"], "three"),
            build("en.u3.l1.e5", "📅 Say: today = Monday", "Today is Monday", extra: ["tomorrow"]),
            type("en.u3.l1.e6", "2️⃣ Type the number", "two")
        ]),
        Lesson(id: LessonID("en.u3.l2"), title: "Places", icon: "🏠", exercises: [
            choice("en.u3.l2.e1", "🏠", ["home", "school", "shop", "city"], "home"),
            choice("en.u3.l2.e2", "🏫", ["school", "home", "work", "park"], "school"),
            choice("en.u3.l2.e3", "🏪", ["shop", "school", "home", "bank"], "shop"),
            choice("en.u3.l2.e4", "🌆", ["city", "home", "shop", "school"], "city"),
            choice("en.u3.l2.e5", "I am ___ home. 🏠", ["at", "in", "on"], "at"),
            build("en.u3.l2.e6", "🏫➡️ Say where you go", "I go to school", extra: ["home"])
        ]),
        Lesson(id: LessonID("en.u3.l3"), title: "Doing Things", icon: "🏃", exercises: [
            choice("en.u3.l3.e1", "🍽️ I ___ bread.", ["eat", "drink", "go"], "eat"),
            choice("en.u3.l3.e2", "🥤 I ___ water.", ["drink", "eat", "sleep"], "drink"),
            choice("en.u3.l3.e3", "😴 I ___ at night.", ["sleep", "eat", "run"], "sleep"),
            choice("en.u3.l3.e4", "🏃 I ___ in the park.", ["run", "sleep", "drink"], "run"),
            choice("en.u3.l3.e5", "She ___ to work. 🚶‍♀️💼", ["goes", "go", "eat"], "goes"),
            build("en.u3.l3.e6", "☕ Say what you drink in the morning", "I drink coffee in the morning", extra: ["eat"]),
            type("en.u3.l3.e7", "🍎🍽️ I ___ an apple. Type the missing word", "eat")
        ]),
        Lesson(id: LessonID("en.u3.l4"), title: "My Day", icon: "🌞", exercises: [
            choice("en.u3.l4.e1", "I ___ up at seven. ⏰", ["wake", "eat", "go"], "wake"),
            choice("en.u3.l4.e2", "I go ___ work. 💼", ["to", "at", "in"], "to"),
            choice("en.u3.l4.e3", "In the evening I ___ TV. 📺", ["watch", "eat", "run"], "watch"),
            build("en.u3.l4.e4", "⏰ Say when you wake up", "I wake up at seven", extra: ["sleep"]),
            build("en.u3.l4.e5", "📺 Say what you watch at night", "I watch TV at night", extra: ["eat"]),
            type("en.u3.l4.e6", "😴 At night I ___. Type the missing word", "sleep")
        ])
    ]
)
