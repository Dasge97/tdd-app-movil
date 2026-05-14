<?php

declare(strict_types=1);

namespace App\Serializer;

use App\Entity\User;

class UserNormalizer
{
    public function normalize(User $user): array
    {
        return [
            'id'               => $user->getId(),
            'username'         => $user->getUsername(),
            'email'            => $user->getEmail(),
            'bio'              => $user->getBio(),
            'avatarUrl'        => $user->getAvatarUrl(),
            'location'         => $user->getLocation(),
            'profileTagline'   => $user->getProfileTagline(),
            'profileTraits'    => $user->getProfileTraits(),
            'reliabilityScore' => $user->getReliabilityScore(),
            'role'             => $user->getRole(),
            'status'           => $user->getStatus(),
            'isAiPersona'      => $user->isAiPersona(),
            'isShadowBanned'   => $user->isShadowBanned(),
            'personaSpecialty' => $user->getPersonaSpecialty(),
            'createdAt'        => $user->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'updatedAt'        => $user->getUpdatedAt()?->format(\DateTimeInterface::ATOM),
        ];
    }

    public function normalizeMany(array $users): array
    {
        return array_map(fn(User $u) => $this->normalize($u), $users);
    }
}
