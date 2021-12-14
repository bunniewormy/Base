#define CLIENT_ONLY;

#include "GameStateBanners.as";

Banner@ getBuildBanner()
{
	u32 duration = 5 * getTicksASecond();
	string text = "Build defenses!";
	string secondary_text = "Increased build speed and resupplies";

	Icon@ left_icon = Icon("InteractionIcons.png", 21, Vec2f(32, 32), Vec2f(160, 32), 0);
	Icon@ right_icon = Icon("InteractionIcons.png", 21, Vec2f(32, 32), Vec2f(96, -32), 0);

	Banner banner(duration, text, left_icon, right_icon, true, secondary_text);

	return banner;
}

Banner@ getGameBanner(int team=0)
{
	u32 duration = 5 * getTicksASecond();
	string text = "Capture the flag!";

	Icon@ left_icon = Icon("BannerIcons.png", 0, Vec2f(32, 32), Vec2f(184, 32), team);
	Icon@ right_icon = Icon("BannerIcons.png", 1, Vec2f(32, 32), Vec2f(120, -32), team);

	Banner banner(duration, text, left_icon, right_icon);

	return banner;
}

Banner@ getWinBanner(int team=0)
{
	u32 duration = 8 * getTicksASecond();
	string text = "{TEAM} team wins";
	string teamName = (team == 0 ? "Blue" : "Red");
	string actual_text = teamName + " team wins";

	Icon@ team_icon = getTeamIcon(team);
	Icon@ left_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(192, 32), team);
	Icon@ right_icon = Icon("MenuItems.png", 31, Vec2f(32, 32), Vec2f(128, -32), team);

	Banner banner(duration, text, left_icon, right_icon, team, true, team_icon);

	return banner;
}

Banner@[] banners;

void onInit(CRules@ this)
{
	banners.insertAt(BannerType::WARMUP_START, getBuildBanner());
	banners.insertAt(BannerType::GAME_START, getGameBanner());
	banners.insertAt(BannerType::GAME_END, getWinBanner());
}

void onReload(CRules@ this)
{
	banners.clear();
	onInit(this);
}

void onRender(CRules@ this)
{
	u8 banner_type = this.get_u8("Animate Banner");

	if (banner_type != BannerType::NONE && this.get_bool("Draw Banner"))
	{
		Driver@ driver = getDriver();
		if (driver !is null)
		{
			if (bannerPos != bannerDest)
			{
				frameTime = Maths::Min(frameTime + (getRenderDeltaTime() / maxTime), 1);

				bannerPos = Vec2f_lerp(bannerStart, bannerDest, frameTime);
			}

			Banner@ banner;

			if (banner_type == BannerType::GAME_END) 
			{
				if (GAME_END >= banners.size()) return;
				@banner = @banners[BannerType::GAME_END];

				if (!this.get_bool("Banner Ready"))
				{
					banner.setTeam(this.getTeamWon());
					banner.main_text = banner.main_text.replace("{TEAM}", (banner.team == 0 ? getTranslatedString("Blue") : getTranslatedString("Red")));
				}
				this.SetGlobalMessage("");
			}
			else if (banner_type == BannerType::WARMUP_START)
			{
				if (WARMUP_START >= banners.size()) return;
				@banner = @banners[BannerType::WARMUP_START];
			} 
			else if (banner_type == BannerType::GAME_START)
			{
				if (GAME_START >= banners.size()) return;
				@banner = @banners[BannerType::GAME_START];
				CPlayer@ p = getLocalPlayer();
				int team = p is null ? 0 : p.getTeamNum();
				// show flags of enemy team colour
				team ^= 1;

				banner.setTeam(team);
			}

			if (this.get_u32("Banner Start") + banner.duration < getGameTime())
			{
				this.set_bool("Banner Ready", false);
				this.set_bool("Draw Banner", false);
				return;
			}

			this.set_bool("Banner Ready", true);
			banner.draw(bannerPos);
		}
	}
	else
	{
		this.set_bool("Banner Ready", false);
		onReload(this);
	}
}