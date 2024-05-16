#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"

//square 2024/5/5


class MrlVehicle {
	int m_vehicleId;
	int m_ownerId;
	Vector3 m_forward;
	Vector3 m_position;
	
	MrlVehicle(int vehicleId,int ownerId,Vector3 forward,Vector3 position) 
	{
		m_forward = forward;
		m_ownerId = ownerId;
		m_position = position;
		m_vehicleId = vehicleId;
	}
}


class MrlMarker {
	int m_markerId;
	float m_time;
	
	MrlMarker(int markerId,float time) 
	{
		m_markerId = markerId;
		m_time = time;
	}
}
	// --------------------------------------------
class MrlManager : Tracker {
	protected Metagame@ m_metagame;
	protected array<MrlVehicle@> mrlVehicles;
	protected array<MrlMarker@> mrlMarkers;

	protected int rp_cost = 50; //rp required for 1 launcher
	protected float range = 300; // max available range
	protected float range_close = 15; // min ...
	protected float angle = 1; //max radian range for launcher to fire
	protected float spread = 10; // rocket target spread radius 
	protected int num = 3; // max launcher num for one player
	protected float markerDur = 3; // marker duration

	protected float m_pi = acos(-1.0f);

	// --------------------------------------------
	MrlManager(Metagame@ metagame) {
		@m_metagame = @metagame;
	}
	float jammerBlockRange = 100;
	array<string> jammers = {"radio_jammer.vehicle","radio_jammer2.vehicle","jeep.vehicle"}; // jammer vehicles
	array<string> noCallRadio = {"13"}; // disable maps
	protected bool CheckRadioStatus(Vector3 pos)
	{
		return false; // disable this line when need Radio jammer check ,while this function havent finished yet as i dont konw how to get mapId leagally right now
		for(uint i=0;i<jammers.length();i++)
		{
			for(int f=0;f<4;f++)
			{
				array<const XmlElement@>@ vehicles = getVehicles(m_metagame,f,jammers[i]);
				if(vehicles.length()>0)
				{
					for(uint j=0;j<vehicles.length();i++)
					{
						int vehicleId = vehicles[j].getIntAttribute("id");
						const XmlElement@ vehicleInfo  = getVehicleInfo(m_metagame, vehicleId);
						Vector3 position = stringToVector3(vehicleInfo.getStringAttribute("position"));
						position = position.subtract(pos);
						if(abs(position.get_opIndex(0))<jammerBlockRange &&  abs(position.get_opIndex(2))<jammerBlockRange)
						{
							return true;
						}
					}
				}
			}
		}
		return false;
	}

	protected void handleVehicleSpawnEvent(const XmlElement@ event) 
    {
        //TagName=vehicle_spawn_event owner_id=0 vehicle_id=3 vehicle_key=mrl.vehicle 
        //_log("getVehicleSpawn",1);
        //_log(event.toString(), 1);
		if(event.getStringAttribute("vehicle_key") == "mrl.vehicle")
		{
			int ownerId = event.getIntAttribute("owner_id");
			int vehicleId = event.getIntAttribute("vehicle_id");
			const XmlElement@ player = getPlayerInfo(m_metagame, ownerId);
			//_log("getPlayerInfo",1);
			//_log(player.toString(), 1);
			//TagName=player aim_target=524.665 2.7451 549.344 character_id=1 color=0.68 0.85 0 1 faction_id=0 name=SINGLE PLAYER player_id=0 profile_hash=ID2172070580 sid=ID0     TagName=access_tag name=pacific     TagName=access_tag name=edelweiss     TagName=access_tag name=ww2     TagName=access_tag name=supporter 
			int characterId = player.getIntAttribute("character_id");
			const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
			//_log("getCharacterInfo",1);
			//_log(character.toString(), 1);
			//TagName=character block=15 16 dead=0 faction_id=0 id=1 leader=1 name=Ray Siffredi player_id=0 position=523.106 2.7451 569.593 rp=5003 soldier_group_name=default squad_size=0 wounded=0 xp=1 
			int rp = character.getIntAttribute("rp");
			if(rp>=rp_cost)
			{
				string command = "<command class='rp_reward' character_id='" + characterId + "' reward='-" + rp_cost + "' />";
				m_metagame.getComms().send(command);
				const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
				Vector3 position = stringToVector3(vehicleInfo.getStringAttribute("position"));
				Vector3 forward = stringToVector3(vehicleInfo.getStringAttribute("forward"));
				MrlVehicle@ thisMrl = MrlVehicle(vehicleId,ownerId,forward,position);
				mrlVehicles.insertLast(thisMrl);
				int pdn = 0;
				for(uint i=mrlVehicles.length()-1;i!=4294967295;i--)
				{
					_log("mrl checke"+i,1);
					if(mrlVehicles[i].m_ownerId == ownerId)
					{
						pdn+=1;
						if(pdn>num)
						{
							removeVehicle(m_metagame, mrlVehicles[i].m_vehicleId);
							mrlVehicles.removeAt(i);
						}
					}
				}
			}
			else
			{
				sendPrivateMessage(m_metagame,ownerId,"50 rp required");
				removeVehicle(m_metagame, vehicleId);
			}
		}


	}

	protected void handlePlayerDieEvent(const XmlElement@ event) 
    {
        //_log("getPlayeDie",1);
        //_log(event.toString(), 1);
		//TagName=player_die combat=1     TagName=target aim_target=519.186 2.62951 572.014 character_id=1 color=0.68 0.85 0 1 faction_id=0 name=SINGLE PLAYER player_id=0 profile_hash=ID2172070580 sid=ID0     TagName=access_tag name=pacific     TagName=access_tag name=edelweiss     TagName=access_tag name=ww2     TagName=access_tag name=supporter 
		int playerId = event.getIntAttribute("player_id");
		for(uint i=mrlVehicles.length()-1;i!=4294967295;i--)
		{
			if(mrlVehicles[i].m_ownerId == playerId)
			{
				removeVehicle(m_metagame, mrlVehicles[i].m_vehicleId);
				mrlVehicles.removeAt(i);
			}
		}
	}
    
	protected void handleVehicleDestroyEvent(const XmlElement@ event) 
    {
		//TagName=vehicle_destroyed_event character_id=3 faction_id=0 owner_id=0 position=523.841 2.74293 568.212 vehicle_id=3 vehicle_key=lounger.vehicle 
        //_log("getVehicleDestroyEvent",1);
        //_log(event.toString(), 1);
		int vehicleId = event.getIntAttribute("vehicle_id");
		for(uint i=mrlVehicles.length()-1;i!=4294967295;i--)
		{
			if(mrlVehicles[i].m_vehicleId  == vehicleId)
			{
				mrlVehicles.removeAt(i);
				break;
			}
		}
	}

	// --------------------------------------------
	protected void handleResultEvent(const XmlElement@ event) 
    {
        //_log("getResultEvent",1);
        //_log(event.toString(), 1);
		//TagName=result_event character_id=3 direction=0.383832 -0.0252173 -0.923058 key=mrl position=523.583 4.20195 568.16 
		if (event.getStringAttribute("key") == "mrl") 
        {
			int characterId = event.getIntAttribute("character_id");
			const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
			
			if (character !is null) 
			{
				//string mapId = m_metagame.getMapId(); ||noCallRadio.find(mapId)>=0
				Vector3 position = stringToVector3(character.getStringAttribute("position"));
				int playerId = character.getIntAttribute("player_id");
				if(CheckRadioStatus(position))
				{
					sendPrivateMessage(m_metagame,playerId,"radio jammed");
					return;
				}
				const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
				int factionId = character.getIntAttribute("faction_id");
				
				if (player !is null && factionId == 0)  
				{
					if (player.hasAttribute("aim_target")) 
					{
						Vector3 target = stringToVector3(player.getStringAttribute("aim_target"));
						int mrlActiveCount=0;
						int lastVehicleId=0;
						for(uint i=mrlVehicles.length()-1;i!=4294967295;i--)
						{
							if(mrlVehicles[i].m_ownerId==playerId)
							{
								if(CheckRadioStatus(mrlVehicles[i].m_position))continue;
								Vector3 line = target.subtract(mrlVehicles[i].m_position);
								if(line.get_opIndex(2)*line.get_opIndex(2)+line.get_opIndex(0)*line.get_opIndex(0) < range*range && line.get_opIndex(2)*line.get_opIndex(2)+line.get_opIndex(0)*line.get_opIndex(0)>range_close*range_close)
								{
									float DirL = atan2(line.get_opIndex(2),line.get_opIndex(0));
									if(DirL<0)DirL = 2*m_pi+DirL;
									float DirM = atan2(mrlVehicles[i].m_forward.get_opIndex(2),mrlVehicles[i].m_forward.get_opIndex(0));
									if(DirM<0)DirM = 2*m_pi+DirM;
									//_log("mrl DirAng "+abs(DirL-DirM),1);
									if(abs(DirL-DirM)<angle || 2*m_pi-angle<abs(DirL-DirM))
									{
										mrlActiveCount += 1;
										Vector3 mrlPosition = mrlVehicles[i].m_position;
										lastVehicleId = mrlVehicles[i].m_vehicleId;
										string c = 
											"<command class='create_instance'" +
											" faction_id='" + factionId + "'" +
											" instance_class='grenade'" +
											" instance_key='mrl_rocket_visual.projectile'" +
											" position='" + mrlPosition.toString() + "'" +
											" character_id='" + characterId + "'" +
											" offset='0 1.1 0' />";
										m_metagame.getComms().send(c);
										c = 
											"<command class='create_instance'" +
											" faction_id='" + factionId + "'" +
											" instance_class='grenade'" +
											" instance_key='mrl_launch_sound.projectile'" +
											" position='" + mrlPosition.toString() + "'" +
											" character_id='" + characterId + "'" +
											" offset='0 -1 0' />";
										m_metagame.getComms().send(c);
										removeVehicle(m_metagame, mrlVehicles[i].m_vehicleId);
									}
								}
							}
						}
						if(mrlActiveCount>0)
						{
							sendFactionMessage(m_metagame,factionId,"mrl on the way");
							XmlElement command("command");
								command.setStringAttribute("class", "set_marker");
								command.setIntAttribute("id", 25000+lastVehicleId);
								command.setIntAttribute("faction_id", factionId);
								command.setIntAttribute("atlas_index", 15);
								command.setFloatAttribute("size", 0.5);
								command.setFloatAttribute("range", spread);
								command.setIntAttribute("enabled", 1);
								command.setStringAttribute("position", target.toString());
								command.setStringAttribute("text", "MRL!");
								command.setStringAttribute("type_key", "call_marker_mrl");
								command.setBoolAttribute("show_in_map_view", true);
								command.setBoolAttribute("show_in_game_view", true);
								command.setBoolAttribute("show_at_screen_edge", false);
							m_metagame.getComms().send(command);
							float remainTime = markerDur;
							for(uint i=0;i<mrlMarkers.length();i++)
							{
								remainTime -= mrlMarkers[i].m_time;
							}
							mrlMarkers.insertLast(MrlMarker(25000+lastVehicleId,remainTime));
						}
						for(uint i=0;i<mrlActiveCount;i++)
						{
							Vector3 origin = target;
							float randTheta = rand(0.0f,2*m_pi);
							float randR = rand(0.0f,spread);
							float spx = randR*cos(randTheta);
							float spy = randR*sin(randTheta);
							origin.m_values[0]+=spx;
							origin.m_values[2]+=spy;
							Vector3 dir = Vector3(0,-0.1,0);
							
							string c = 
								"<command class='create_instance'" +
								" faction_id='" + factionId + "'" +
								" instance_class='grenade'" +
								" instance_key='mrl_rocket_sound.projectile'" +
								" position='" + origin.toString() + "'" +
								" character_id='" + characterId + "'" +
								" offset='" + dir.toString() + "' />";
							m_metagame.getComms().send(c);
							
							origin.m_values[1]+=(50.0f + i*5.0f);
							
							c = 
								"<command class='create_instance'" +
								" faction_id='" + factionId + "'" +
								" instance_class='grenade'" +
								" instance_key='mrl_rocket.projectile'" +
								" position='" + origin.toString() + "'" +
								" character_id='" + characterId + "'" +
								" offset='" + dir.toString() + "' />";
							m_metagame.getComms().send(c);
							
						}
						if(mrlActiveCount==0)
						{
							sendPrivateMessage(m_metagame,playerId,"no available mrl in range");
						}
					}
				}
			}
        }

	}

	bool hasStarted() const 
	{
		return true;
	}

	void update(float time) 
	{
		if(mrlMarkers.length()>0)
		{
			mrlMarkers[0].m_time -= time;
			if(mrlMarkers[0].m_time <0)
			{
				if(mrlMarkers.length>1)
				{
					mrlMarkers[1].m_time+=mrlMarkers[0].m_time;
				}
				XmlElement command("command");
					command.setStringAttribute("class", "set_marker");
					command.setIntAttribute("id", mrlMarkers[0].m_markerId);
					command.setIntAttribute("enabled", 0);
					command.setIntAttribute("faction_id", 0);
				m_metagame.getComms().send(command);
				mrlMarkers.removeAt(0);
			}
		}
	}

}