<?php

declare(strict_types=1);

namespace App\Serializer;

use App\Entity\User;

class UserNormalizer
{
    /**
     * Normalizes a User. Public data only by default; pass $includePrivate=true to expose
     * email and other private fields (use only for /me endpoints).
     */
    public function normalize(User $user, bool $includePrivate = false): array
    {
        $data = [
            'id'               => $user->getId(),
            'username'         => $user->getUsername(),
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

        if ($includePrivate) {
            $data['email'] = $user->getEmail();
        }

        return $data;
    }

    public function normalizeMany(array $users): array
    {
        return array_map(fn(User $u) => $this->normalize($u), $users);
    }
}
