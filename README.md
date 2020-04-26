# FEC Checker - A Twitter bot to see who verified accounts have donated to. 

Ever find yourself being told authoritatively by some Twitter pundit that you and you personally are responsible for making sure some lesser of two evils candidate wins, even if you spent the last 6 months grinding it out for your preferred candidate in the primaries? Want to see if they actually have any skin in the game?

Just tag @CheckerFEC in the comments and we'll search the Twitter user's name in the FEC individual contribution records. Obviously, this won't work for people under a pseudonym, so this is mostly intended for blue checks. 

## Check if someone has donated to a specific candidate

If you want to see if the person has donated to a specific candidate, simply comment "[candidate]?" in the reply when you tag FEC Checker. 

Example: @mattyglesias @CheckerFEC Obama?

In the current version, only single words before ? are accepted (i.e. Barack Obama? will work, but Barack will be ignored.) This limits usefulness somewhat in cases where the candidate committee uses only one of the candidate's names (e.g. Bernie 2020.) If this thing gains traction we'll consider adding some handling to fix this.

## Fake screen name?

If you know the person's real name, you can call this using the [name:] parameter. 

Example: @ByYourLogic @CheckerFEC [name: Felix Biederman]

