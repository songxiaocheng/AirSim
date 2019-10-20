#include "ManualPoseController.h"
#include "AirBlueprintLib.h"


void UManualPoseController::initializeForPlay(UInputComponent* InputComponent)
{
    actor_ = nullptr;

    input_component_ = InputComponent;
    last_velocity_ = FVector::ZeroVector;
}

void UManualPoseController::setActor(AActor* actor)
{
    //if we already have attached actor
    if (actor_) {
        removeInputBindings();
    }

    actor_ = actor;

    if (actor_ != nullptr) {
        resetDelta();
        setupInputBindings();
        position_ = actor_->GetActorLocation();
        rotation_ = actor_->GetActorRotation();
    }
}

AActor* UManualPoseController::getActor() const
{
    return actor_;
}

void UManualPoseController::updateActorPose(float dt)
{
    if (actor_ != nullptr) {
        updateDeltaPosition(dt);
        position_ += delta_position_;
        rotation_ += delta_rotation_;
        if (rotation_.Pitch < -90) rotation_.Pitch = -90;
        if (rotation_.Pitch > 90) rotation_.Pitch = 90;
        actor_->SetActorLocationAndRotation(position_, rotation_);
        resetDelta();
    }
    else {
        UAirBlueprintLib::LogMessageString("UManualPoseController::updateActorPose should not be called when actor is not set", "", LogDebugLevel::Failure);
    }
}

void UManualPoseController::getDeltaPose(FVector& delta_position, FRotator& delta_rotation) const
{
    delta_position = delta_position_;
    delta_rotation = delta_rotation_;
}

void UManualPoseController::resetDelta()
{
    delta_position_ = FVector::ZeroVector;
    delta_rotation_ = FRotator::ZeroRotator;
}

void UManualPoseController::removeInputBindings() const
{
    input_component_->AxisBindings.Empty();
}

void UManualPoseController::setupInputBindings()
{
    UAirBlueprintLib::EnableInput(actor_);
    check(input_component_);
    input_component_->BindAxis("MoveForward", this, &UManualPoseController::inputManualForward);
    input_component_->BindAxis("MoveDown", this, &UManualPoseController::inputManualDown);
    input_component_->BindAxis("MoveRight", this, &UManualPoseController::inputManualRight);
    input_component_->BindAxis("RotateRight", this, &UManualPoseController::inputManualRightYaw);
    input_component_->BindAxis("RotateDown", this, &UManualPoseController::inputManualDownPitch);
}

void UManualPoseController::updateDeltaPosition(float dt)
{
    if (!FMath::IsNearlyZero(move_input_.SizeSquared())) {
        if (FMath::IsNearlyZero(acceleration_))
            last_velocity_ = move_input_ * 1000;
        else
            last_velocity_ += move_input_ * (acceleration_ * dt);
        delta_position_ += actor_->GetActorRotation().RotateVector(last_velocity_ * dt);
    } else {
        delta_position_ = last_velocity_ = FVector::ZeroVector;
    }
}

void UManualPoseController::inputManualForward(float val)
{
    move_input_.X = val;
}

void UManualPoseController::inputManualRight(float val)
{
    move_input_.Y = val;
}

void UManualPoseController::inputManualDown(float val)
{
    move_input_.Z = -val;
}

void UManualPoseController::inputManualRightYaw(float val)
{
    if (!FMath::IsNearlyEqual(val, 0.f))
        delta_rotation_.Add(0, val, 0);
}

void UManualPoseController::inputManualDownPitch(float val)
{
    if (!FMath::IsNearlyEqual(val, 0.f))
        delta_rotation_.Add(-val, 0, 0);
}
