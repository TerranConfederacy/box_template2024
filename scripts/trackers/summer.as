#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"  
#include "query_helpers.as"
#include "query_helpers2.as" 

//square 2024/5/22
//used for deliver MK47
//stab oldman to spawn mk47,playerkill are not required as druid tac is recommand and oldman seemed too lethal
//11:39:11: SCRIPT:  received: TagName=character_kill key= method_hint=stab     TagName=killer block=12 14 dead=0 faction_id=0 id=11 leader=1 name=Nikita Sokol player_id=0 position=428.551 4.3014 499.254 rp=60 soldier_group_name=default squad_size=0 wounded=0 xp=0     TagName=target block=12 14 dead=0 faction_id=1 id=9 leader=1 name=Uwe Neururer player_id=-1 position=428.102 4.30089 498.737 rp=0 soldier_group_name=default_ai squad_size=2 wounded=0 xp=0 
//agName=player aim_target=491.566 4.21569 509.884 character_id=21 color=0.68 0.85 0 1 faction_id=0 name=MR. GREEN player_id=0 profile_hash=ID3446646883 sid=ID0 





class Summer : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	Summer(Metagame@ metagame) {
		_log("start it");
		@m_metagame = @metagame;
		m_metagame.getComms().send("<command class='set_metagame_event' name='character_kill' enabled='1' />");

	}

	// --------------------------------------------
	bool hasEnded() const {
		return false;
	}

	// -------------------------------------------- 
	bool hasStarted() const {
		return true;
	}



	protected void handleCharacterKillEvent(const XmlElement@ event) 
	{
		const XmlElement@ target = event.getFirstElementByTagName("target");
		if (target is null) return; 
		string targetName =	target.getStringAttribute("soldier_group_name");
		_log("kill a "+targetName);
		if(targetName != "off duty veteran")return;
		string killMethod = event.getStringAttribute("method_hint");
		if (killMethod!="stab") return;
		int dropRate = 33;
		if(rand(0,99)<dropRate)
		{
			string targetP = target.getStringAttribute("position");
			string c = "<command class='create_instance' instance_class='weapon' instance_key='mk47.weapon' position='" + targetP + "' faction_id='0' />";
			m_metagame.getComms().send(c);
		}
	}
}

