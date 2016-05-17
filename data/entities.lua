-- Rogue with Friends - a 2D, real-time, multiplayer roguelike
-- ---------------------------------------------------------------
-- Released under the GNU AGPLv3 or later. See README.md for info.

return {

Human = {
	moveSpeed = {Ground = 3},
	hitPoints = 10,
	damage = 1,
	attackSpeed = 4
};

Monster = {
	moveSpeed = {Ground = 2},
	hitPoints = 5,
	damage = 1,
	attackSpeed = 2
};

Boss = {
	moveSpeed = {Ground = 1},
	hitPoints = 10,
	damage = 1,
	attackSpeed = 1
};
}
