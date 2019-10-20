#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GameFramework/PlayerInput.h"

#include "ManualPoseController.generated.h"

UCLASS()
class AIRSIM_API UManualPoseController : public UObject {
    GENERATED_BODY()

public:
    void initializeForPlay(UInputComponent* InputComponent);
    void setActor(AActor* actor);
    AActor* getActor() const;
    void updateActorPose(float dt);
    void getDeltaPose(FVector& delta_position, FRotator& delta_rotation) const;
    void resetDelta();
    void updateDeltaPosition(float dt);

private:
    void inputManualRight(float val);
    void inputManualForward(float val);
    void inputManualDown(float val);
    void inputManualRightYaw(float val);
    void inputManualDownPitch(float val);

    void setupInputBindings();	
    void removeInputBindings() const;

private:


    FVector delta_position_;
    FRotator delta_rotation_;
    FVector position_;
    FRotator rotation_;

    UInputComponent* input_component_;

    AActor *actor_;

    float acceleration_ = 0;
    FVector last_velocity_;
    FVector move_input_;

};