#include "DialogueFactory.h"
#include <QMap>

DialogueTree* DialogueFactory::createDialogue(const QString &dialogueId)
{
    // Static cache to prevent memory leaks
    static QMap<QString, DialogueTree*> cache;

    if (cache.isEmpty()) {
        // ================================================================
        // DIALOGUE 1: Village Elder Introduction
        // ================================================================
        DialogueTree* elderIntro = new DialogueTree();
        elderIntro->id = "elder_intro";
        elderIntro->npcName = "Village Elder";
        elderIntro->startNodeId = "greeting";

        // Node: Greeting
        DialogueNode greeting;
        greeting.id = "greeting";
        greeting.speaker = "Village Elder";
        greeting.text = R"(Greetings, brave adventurer. Dark times have fallen upon our village.
Shadow creatures emerge from the forest at night, and our people live in fear.)";
        greeting.endsDialogue = false;

        DialogueChoice choice1;
        choice1.text = "What's happening here?";
        choice1.targetNodeId = "explain";

        DialogueChoice choice2;
        choice2.text = "I'll help immediately!";
        choice2.targetNodeId = "accept_quest";

        greeting.choices.append(choice1);
        greeting.choices.append(choice2);
        elderIntro->nodes["greeting"] = greeting;

        // Node: Explanation
        DialogueNode explain;
        explain.id = "explain";
        explain.speaker = "Village Elder";
        explain.text = R"(For generations, the Shadow Wolves stayed deep in the Whispering Woods.
But something has changed. They grow bolder, venturing closer each night.
We need someone brave enough to drive them back.)";
        explain.endsDialogue = false;

        DialogueChoice choice3;
        choice3.text = "I'll take care of it.";
        choice3.targetNodeId = "accept_quest";

        DialogueChoice choice4;
        choice4.text = "This sounds dangerous. I need time to think.";
        choice4.targetNodeId = "goodbye";

        explain.choices.append(choice3);
        explain.choices.append(choice4);
        elderIntro->nodes["explain"] = explain;

        // Node: Accept Quest
        DialogueNode acceptQuest;
        acceptQuest.id = "accept_quest";
        acceptQuest.speaker = "Village Elder";
        acceptQuest.text = R"(Thank you, brave one. May fortune favor you in the Whispering Woods.
Defeat at least three Shadow Wolves and return to me with news of your victory.)";
        acceptQuest.endsDialogue = true;

        DialogueChoice choice5;
        choice5.text = "I won't let you down.";
        choice5.targetNodeId = "";  // Empty = end dialogue

        DialogueEffect unlockEffect;
        unlockEffect.type = "UnlockQuest";
        unlockEffect.target = "main_quest_01";
        unlockEffect.value = 0;
        choice5.effects.append(unlockEffect);

        DialogueEffect goldBonus;
        goldBonus.type = "GiveGold";
        goldBonus.target = "";
        goldBonus.value = 50;
        choice5.effects.append(goldBonus);

        acceptQuest.choices.append(choice5);
        elderIntro->nodes["accept_quest"] = acceptQuest;

        // Node: Goodbye
        DialogueNode goodbye;
        goodbye.id = "goodbye";
        goodbye.speaker = "Village Elder";
        goodbye.text = "Very well. Return when you're ready to face the shadows.";
        goodbye.endsDialogue = true;

        DialogueChoice choice6;
        choice6.text = "I'll be back.";
        choice6.targetNodeId = "";
        goodbye.choices.append(choice6);
        elderIntro->nodes["goodbye"] = goodbye;

        cache["elder_intro"] = elderIntro;

        // ================================================================
        // DIALOGUE 2: Elder Quest Completion
        // ================================================================
        DialogueTree* elderComplete = new DialogueTree();
        elderComplete->id = "elder_complete";
        elderComplete->npcName = "Village Elder";
        elderComplete->startNodeId = "celebration";

        DialogueNode celebration;
        celebration.id = "celebration";
        celebration.speaker = "Village Elder";
        celebration.text = R"(You've returned! The howling has stopped, and the forest feels safer already.
You have our deepest gratitude, hero.)";
        celebration.endsDialogue = true;

        DialogueChoice accept;
        accept.text = "Happy to help. What's next?";
        accept.targetNodeId = "";

        DialogueEffect xpReward;
        xpReward.type = "GiveXP";
        xpReward.value = 100;
        accept.effects.append(xpReward);

        DialogueEffect goldReward;
        goldReward.type = "GiveGold";
        goldReward.value = 150;
        accept.effects.append(goldReward);

        celebration.choices.append(accept);
        elderComplete->nodes["celebration"] = celebration;

        cache["elder_complete"] = elderComplete;

        // ================================================================
        // DIALOGUE 3: Merchant Greeting
        // ================================================================
        DialogueTree* merchant = new DialogueTree();
        merchant->id = "merchant_greeting";
        merchant->npcName = "Traveling Merchant";
        merchant->startNodeId = "greeting_m";

        DialogueNode greetingM;
        greetingM.id = "greeting_m";
        greetingM.speaker = "Traveling Merchant";
        greetingM.text = R"(Welcome, welcome! I've got the finest wares this side of the kingdom!
Swords, potions, armor - you name it, I've got it!)";
        greetingM.endsDialogue = false;

        DialogueChoice browse;
        browse.text = "Show me what you have.";
        browse.targetNodeId = "browse";

        DialogueChoice rumors;
        rumors.text = "Any rumors from your travels?";
        rumors.targetNodeId = "rumors";

        DialogueChoice leave;
        leave.text = "Maybe later.";
        leave.targetNodeId = "";

        greetingM.choices.append(browse);
        greetingM.choices.append(rumors);
        greetingM.choices.append(leave);
        merchant->nodes["greeting_m"] = greetingM;

        DialogueNode browseNode;
        browseNode.id = "browse";
        browseNode.speaker = "Traveling Merchant";
        browseNode.text = "Take your time! Everything's top quality, guaranteed!";
        browseNode.endsDialogue = true;

        DialogueChoice buyChoice;
        buyChoice.text = "I'll browse your shop.";
        buyChoice.targetNodeId = "";
        browseNode.choices.append(buyChoice);
        merchant->nodes["browse"] = browseNode;

        DialogueNode rumorsNode;
        rumorsNode.id = "rumors";
        rumorsNode.speaker = "Traveling Merchant";
        rumorsNode.text = R"(Well, I heard tell of strange lights in the old ruins to the north.
Some say it's treasure, others say it's cursed. Either way, sounds profitable!)";
        rumorsNode.endsDialogue = true;

        DialogueChoice interesting;
        interesting.text = "Interesting. Thanks for the tip.";
        interesting.targetNodeId = "";
        rumorsNode.choices.append(interesting);
        merchant->nodes["rumors"] = rumorsNode;

        cache["merchant_greeting"] = merchant;

        // ================================================================
        // DIALOGUE 4: Scholar Warning
        // ================================================================
        DialogueTree* scholar = new DialogueTree();
        scholar->id = "scholar_warning";
        scholar->npcName = "Scholar Aldric";
        scholar->startNodeId = "warning";

        DialogueNode warning;
        warning.id = "warning";
        warning.speaker = "Scholar Aldric";
        warning.text = R"(Ah, an adventurer! Please, listen carefully. I've deciphered ancient texts that speak of a great darkness.
The Shadow Wolves are merely symptoms of a deeper corruption.)";
        warning.endsDialogue = false;

        DialogueChoice listen;
        listen.text = "Tell me more about this corruption.";
        listen.targetNodeId = "corruption";

        DialogueChoice dismiss;
        dismiss.text = "Sounds like superstition to me.";
        dismiss.targetNodeId = "offended";

        warning.choices.append(listen);
        warning.choices.append(dismiss);
        scholar->nodes["warning"] = warning;

        DialogueNode corruption;
        corruption.id = "corruption";
        corruption.speaker = "Scholar Aldric";
        corruption.text = R"(The texts speak of an ancient evil, sealed away centuries ago.
The seals are weakening. If my research is correct, we have little time before catastrophe strikes.)";
        corruption.endsDialogue = true;

        DialogueChoice understand;
        understand.text = "I'll do what I can to help.";
        understand.targetNodeId = "";
        corruption.choices.append(understand);
        scholar->nodes["corruption"] = corruption;

        DialogueNode offended;
        offended.id = "offended";
        offended.speaker = "Scholar Aldric";
        offended.text = "Hmph. Suit yourself. Don't come crying to me when the darkness spreads.";
        offended.endsDialogue = true;

        DialogueChoice leave2;
        leave2.text = "Goodbye.";
        leave2.targetNodeId = "";
        offended.choices.append(leave2);
        scholar->nodes["offended"] = offended;

        cache["scholar_warning"] = scholar;

        // ================================================================
        // DIALOGUE 5: Innkeeper Small Talk
        // ================================================================
        DialogueTree* innkeeper = new DialogueTree();
        innkeeper->id = "innkeeper_chat";
        innkeeper->npcName = "Innkeeper Martha";
        innkeeper->startNodeId = "welcome";

        DialogueNode welcome;
        welcome.id = "welcome";
        welcome.speaker = "Innkeeper Martha";
        welcome.text = "Welcome to the Rusty Tankard! What can I get for you today?";
        welcome.endsDialogue = false;

        DialogueChoice rest;
        rest.text = "I'd like to rest. (50 gold)";
        rest.targetNodeId = "rest_response";
        rest.requiresLevel = false;

        DialogueChoice gossip;
        gossip.text = "Any interesting gossip?";
        gossip.targetNodeId = "gossip_node";

        DialogueChoice nothing;
        nothing.text = "Nothing right now.";
        nothing.targetNodeId = "";

        welcome.choices.append(rest);
        welcome.choices.append(gossip);
        welcome.choices.append(nothing);
        innkeeper->nodes["welcome"] = welcome;

        DialogueNode restResponse;
        restResponse.id = "rest_response";
        restResponse.speaker = "Innkeeper Martha";
        restResponse.text = "Sleep well, dearie. You look like you could use it!";
        restResponse.endsDialogue = true;

        DialogueChoice sleep;
        sleep.text = "Thank you.";
        sleep.targetNodeId = "";
        restResponse.choices.append(sleep);
        innkeeper->nodes["rest_response"] = restResponse;

        DialogueNode gossipNode;
        gossipNode.id = "gossip_node";
        gossipNode.speaker = "Innkeeper Martha";
        gossipNode.text = R"(Well, there's been talk of strange noises from the old cemetery.
And young Tom swears he saw lights floating through the trees last night.
Probably just his imagination... probably.)";
        gossipNode.endsDialogue = true;

        DialogueChoice thanks;
        thanks.text = "Thanks for the information.";
        thanks.targetNodeId = "";
        gossipNode.choices.append(thanks);
        innkeeper->nodes["gossip_node"] = gossipNode;

        cache["innkeeper_chat"] = innkeeper;
    }

    return cache.value(dialogueId, nullptr);
}

QList<DialogueTree*> DialogueFactory::getAllDialogues()
{
    static QList<DialogueTree*> allDialogues;

    if (allDialogues.isEmpty()) {
        allDialogues.append(createDialogue("elder_intro"));
        allDialogues.append(createDialogue("elder_complete"));
        allDialogues.append(createDialogue("merchant_greeting"));
        allDialogues.append(createDialogue("scholar_warning"));
        allDialogues.append(createDialogue("innkeeper_chat"));
    }

    return allDialogues;
}

DialogueTree* DialogueFactory::getDialogueForQuest(const QString &questId)
{
    if (questId == "main_quest_01") {
        return createDialogue("elder_intro");
    }

    return nullptr;
}
