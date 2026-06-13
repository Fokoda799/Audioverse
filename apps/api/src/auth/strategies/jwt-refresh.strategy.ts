import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy, StrategyOptionsWithRequest } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';

interface JwtPayload {
  sub: string;
  email: string;
}

@Injectable()
export class JwtRefreshStrategy extends PassportStrategy(Strategy, 'jwt-refresh') {
  constructor(private readonly config: ConfigService) {
    const options: StrategyOptionsWithRequest = {
      jwtFromRequest: ExtractJwt.fromBodyField('refresh_token'),

      secretOrKey: config.getOrThrow<string>('JWT_REFRESH_SECRET'),

      passReqToCallback: true,

      ignoreExpiration: false,
    };

    super(options);
  }

  async validate(req: Request, payload: JwtPayload) {
    const refreshToken = req.body?.refresh_token as string | undefined;

    if (!refreshToken) {
      throw new UnauthorizedException('Refresh token is missing from the request body');
    }

    // Returned value is automatically attached to req.user by Passport
    return {
      sub: payload.sub,
      email: payload.email,
      refreshToken,
    };
  }
}