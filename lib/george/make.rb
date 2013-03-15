class George
  module Make

    TEMPLATES = {
      'tea' => [
        "Are you putting the kettle on? I'd love one.",
        "You wouldn't want the world to discover your EVIL ALIEN IDENTITY NOW, RIGHT?"
      ],
      'judge' => [
        "With the judging eyes, the judgiiiiing",
        "Yeh, I know it's crazy, I just met you, I'll judge you maybe",
        "it's all wrong"
      ],
      'help' => [
        "I need some emergency leftover pasta",
        "what does this javascripts do?",
        ""
      ],
      'supertrain' => [
        "George, it's time. Get your bag."
      ]
    }

    GENERAL_TEMPLATES = [
      "George. " * 12 + "When should we kill him?",
      "Please may I have some <%= beverage %>?",
      "Isn't it time you had some <%= beverage %>?"
    ]

    def self.message(beverage)
      list = GENERAL_TEMPLATES
      if extra = TEMPLATES[beverage.strip.downcase]
        list = list + extra
      end
      template = list[rand(list.size)]
      ERB.new(template).result(binding)
    end

  end
end

