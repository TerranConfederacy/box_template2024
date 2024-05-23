#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as" 
#include "log.as"  
#include "query_helpers.as"
#include "query_helpers2.as" 

//square 2024/5/22





 
class IceTrade : Tracker {
	protected Metagame@ m_metagame;




	IceTrade(Metagame@ metagame) {
		_log("start it");
		@m_metagame = @metagame;
	}

	// --------------------------------------------
	bool hasEnded() const {
		return false;
	}

	// -------------------------------------------- 
	bool hasStarted() const {
		return true;
	}



	int SearchVehicles(Vector3 Pos)
	{
		_log("search Vehicle");
		array<const XmlElement@>@ vehicles = getAllVehicles(m_metagame, 0);
		for (uint i = 0;i<vehicles.length();i++)
		{
			Vector3 vehiclePos = stringToVector3(vehicles[i].getStringAttribute("position"));
			if (checkRange(Pos, vehiclePos, 3.0f))
			{
				int vehicleId = vehicles[i].getIntAttribute("id");
				const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
				if (vehicleInfo !is null) 
				{
					string vehicleKey = vehicleInfo.getStringAttribute("key");
					if (vehicleKey == "icecream.vehicle")
					{
						return vehicleId;
					}
				}
			}
		}
		return -1;
	}



	void rewardPlayer(string playerId) 
	{
		_log("reward You lottery");

		string RewardKey = "lottery.carry_item";
		string itemType = "carry_item"; 
		int lsPlayerId = parseInt(playerId);
		const XmlElement@ info = getPlayerInfo(m_metagame,lsPlayerId);
		int characterId = info.getIntAttribute("character_id");
		@info = getCharacterInfo(m_metagame, characterId);
		if (info !is null) 
		{
			XmlElement c("command");
			c.setStringAttribute("class", "update_inventory");

			c.setIntAttribute("character_id", characterId); 
			c.setIntAttribute("container_type_id", 2);
			{
				XmlElement j("item");
				j.setStringAttribute("class", itemType);
				j.setStringAttribute("key", RewardKey);
				c.appendChild(j);
			}
			m_metagame.getComms().send(c);		
		}
	}

	protected array<string> dirnks = {"foxicle.carry_item","orange_juice.carry_item","snowpeak_coffee.carry_item","energy_drink.carry_item","beer_can.carry_item"};
	dictionary playerConnection;

	dictionary playerTradeDrinks;
	void addDrink(string playerIdWithDrinkId)
	{
		if(playerTradeDrinks.exists(playerIdWithDrinkId))
		{
			int count;
			playerTradeDrinks.get(playerIdWithDrinkId,count);
			count = count+1;
			playerTradeDrinks.set(playerIdWithDrinkId,count);
			if(count>=5)
			{
				rewardPlayer(playerIdWithDrinkId);
				playerTradeDrinks.delete(playerIdWithDrinkId);
			}
		}
		else
		{
			playerTradeDrinks.set(playerIdWithDrinkId,1);
		}
	}
	
	protected void handleItemDropEvent(const XmlElement@ event) 
	{
		_log("see this");
		string itemKey = event.getStringAttribute("item_key");
		int drinkId = dirnks.find(itemKey);
		if(event.getIntAttribute("target_container_type_id")!=1 || drinkId<0)return;
		int lsPlayerId   = event.getIntAttribute("player_id");
		string playerId = formatInt(lsPlayerId);
		string playerIdWithDrinkId = formatInt(lsPlayerId)+"&"+formatInt(drinkId);
		if(!playerConnection.exists(playerId))
		{
			Vector3 Pos    = stringToVector3(event.getStringAttribute("position"));	 
			int workPlaceId= SearchVehicles(Pos);
			if(workPlaceId == -1)
			{
				playerConnection.set(playerId,false);
				return;
			}
			else
			{
				playerConnection.set(playerId,true);
				addDrink(playerIdWithDrinkId);
				return;
			}
		}
		else
		{
			bool pd = false;
			playerConnection.get(playerId,pd);
			if(pd)
			{
				addDrink(playerIdWithDrinkId);
				return;
			}
		}
	}

	float cleanTime = 1.0f;
	void update(float time) 
	{
		cleanTime -=time;
		if(cleanTime<0)
		{
			cleanTime = 1.0f;
			playerConnection.deleteAll();
		}
	}
}

