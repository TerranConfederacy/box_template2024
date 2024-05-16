#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

//square 2024/5/9


class Cover {
	int m_vehicleId;
	int m_ownerId;
	Vector3 m_forward;
	Vector3 m_position;
	
	Cover(int vehicleId,int ownerId) 
	{
		m_ownerId = ownerId;
		m_vehicleId = vehicleId;
	}
}


	// --------------------------------------------
class CoverManager : Tracker {
	protected Metagame@ m_metagame;
	protected array<Cover@> covers;
	int num =5;

	CoverManager(Metagame@ metagame) {
		@m_metagame = @metagame;
	}
	
	protected void handleVehicleSpawnEvent(const XmlElement@ event) 
    {
		if(event.getStringAttribute("vehicle_key") == "sandbag_cover.vehicle")
		{
			int ownerId = event.getIntAttribute("owner_id");
			int vehicleId = event.getIntAttribute("vehicle_id");
			const XmlElement@ player = getPlayerInfo(m_metagame, ownerId);
			int characterId = player.getIntAttribute("character_id");
			Cover@ thisCover = Cover(vehicleId,ownerId);
			covers.insertLast(thisCover);
			int pdn = 0;
			for(uint i=covers.length()-1;i!=4294967295;i--)
			{
					_log("cover checke"+i,1);
				if(covers[i].m_ownerId == ownerId)
				{
					pdn+=1;
					if(pdn>num)
					{
						removeVehicle(m_metagame, covers[i].m_vehicleId);
						covers.removeAt(i);
					}
				}
			}
		}
	}


	protected void handlePlayerDieEvent(const XmlElement@ event) 
    {
        int playerId = event.getIntAttribute("player_id");
		for(uint i=covers.length()-1;i!=4294967295;i--)
		{
			if(covers[i].m_ownerId == playerId)
			{
				removeVehicle(m_metagame, covers[i].m_vehicleId);
				covers.removeAt(i);
			}
		}
	}
	
	protected void handlePlayerDisconnectEvent(const XmlElement@ event) 
    {
        int playerId = event.getIntAttribute("player_id");
		for(uint i=covers.length()-1;i!=4294967295;i--)
		{
			if(covers[i].m_ownerId == playerId)
			{
				removeVehicle(m_metagame, covers[i].m_vehicleId);
				covers.removeAt(i);
			}
		}
	}
    
	protected void handleVehicleDestroyEvent(const XmlElement@ event) 
    {
		int vehicleId = event.getIntAttribute("vehicle_id");
		for(uint i=covers.length()-1;i!=4294967295;i--)
		{
			if(covers[i].m_vehicleId  == vehicleId)
			{
				covers.removeAt(i);
				break;
			}
		}
	}

	bool hasStarted() const 
	{
		return true;
	}



}