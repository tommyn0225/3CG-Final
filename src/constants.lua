-- src/constants.lua
local constants = {}

constants.TARGET_SCORE = 50

constants.CARD_DEFS = {
    { id="wooden_cow", name="Wooden Cow", cost=1, power=1, text="Vanilla" },
    { id="pegasus",    name="Pegasus",    cost=3, power=5, text="Vanilla" },
    { id="minotaur",   name="Minotaur",   cost=5, power=9, text="Vanilla" },
    { id="titan",      name="Titan",      cost=6, power=12,text="Vanilla" },
    { id="zeus",       name="Zeus",       cost=7, power=4, text="When Revealed: Lower the power of each card in your opponent's hand by 1.", ability="zeus" },
    { id="hermes",     name="Hermes",     cost=3, power=1, text="When Revealed: Moves to another location.", ability="hermes" },
    { id="hydra",      name="Hydra",      cost=6, power=3, text="Add two copies to your hand when this card is discarded.", ability="hydra" },
    { id="midas",      name="Midas",      cost=8, power=2, text="When Revealed: Set ALL cards here to 3 power.", ability="midas" },
    { id="aphrodite",  name="Aphrodite",  cost=6, power=3, text="When Revealed: Lower the power of each enemy card here by 1.", ability="aphrodite" },
    { id="athena",     name="Athena",     cost=6, power=2, text="Gain +1 power when you play another card here.", ability="athena" },
    { id="apollo",     name="Apollo",     cost=3, power=2, text="When Revealed: Gain +2 mana next turn.", ability="apollo" },
    { id="nyx",        name="Hades",        cost=7, power=3, text="When Revealed: Gain +2 power for each card in your discard pile.", ability="hades" },
    { id="daedalus",   name="Daedalus",   cost=5, power=3, text="When Revealed: Add a Wooden Cow to each other location.", ability="daedalus" },
    { id="helios",     name="Ares",     cost=6, power=4,text="When Revealed: Gain +2 power for each enemy card here.", ability="ares" },
    -- new cards
    { id="demeter",    name="Demeter",     cost=3, power=2, text="When Revealed: Both players draw a card.", ability="demeter"},
    { id="ship_of_theseus",    name="Ship of Theseus",     cost=6, power=4, text="When Revealed: Add a copy with +1 power to your hand.", ability="ship_of_theseus"},
    { id="sword_of_damocles",    name="Sword of Damocles",     cost=5, power=5, text="End of Turn: Loses 1 power if not winning this location.", ability="sword_of_damocles"},
    { id="persephone",    name="Persephone",     cost=2, power=1, text="When Revealed: Discard the lowest power card in your hand.", ability="persephone"},
    { id="dionysus",    name="Dionysus",     cost=6, power=3, text="When Revealed: Gain +2 power for each of your other cards here.", ability="dionysus"},

    

}

return constants
