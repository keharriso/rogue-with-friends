-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

return {

Human = {
	moveSpeed = {Ground = 4},
	hitPoints = 15,
	damage = 1,
	attackSpeed = 3
};

Monster = {
	moveSpeed = {Ground = 2},
	hitPoints = 5,
	damage = 1,
	attackSpeed = 2
};

Boss = {
	moveSpeed = {Ground = 1},
	hitPoints = 20,
	damage = 3,
	attackSpeed = 2
};
}
