package com.example.petadoptioncommunity.identity;
import java.util.Collection;
import java.util.function.Supplier;
public interface IdentityPort {
 record Actor(String userId,String role,long stateVersion,long authVersion,String sessionKey){ @Override public String toString(){return "Actor[redacted]";} }
 record PublicIdentity(String userId,String nickname){}
 Actor requireActive(String requestCredential);
 <T> T withActiveActor(Actor actor,Collection<String> lockedTargetIds,Supplier<T> transactionWork);
 PublicIdentity readPublicIdentity(String userId);
}
